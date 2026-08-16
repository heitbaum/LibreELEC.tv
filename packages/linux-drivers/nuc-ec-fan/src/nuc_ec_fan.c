// SPDX-License-Identifier: GPL-2.0-only
/*
 * nuc_ec_fan - expose the Intel NUC embedded-controller fan tachometer
 *              as a standard hwmon device.
 *
 * Background
 * ----------
 * On NUC12 (Wall Street Canyon) the fan speed is not reachable through any
 * of the usual paths:
 *
 *   - there is no Super-I/O sensor chip, so no it87/nct6775 hwmon source;
 *   - the ACPI fan objects (\_TZ_.FAN0..FAN4) are legacy on/off cooling
 *     devices with no _FPS, so the thermal framework exposes no RPM;
 *   - the firmware's own sensor interface (\_SB.PTID.OSDD) is gated on
 *     \_SB.PC00.LPCB.H_EC.ECAV, and that EC device reports _STA = 0, so
 *     ECAV is never set and every EC-sourced PTID reading is dead.
 *
 * The kernel nevertheless owns a working EC (brought up from the ECDT at
 * boot, EC_CMD/EC_SC=0x66 EC_DATA=0x62).  The DSDT names the EC RAM offsets
 * it cares about as plain constants inside the H_EC device, e.g.
 *
 *   Name(CFAN, 0x05)   Name(PECH, 0x83)   Name(PECL, 0x82)
 *
 * and reads them via ECRD(RefOf(<name>)).  This driver performs the same
 * reads directly through ec_read(), which takes the kernel's EC mutex, so
 * it cannot race the ACPI EC driver the way raw 0x62/0x66 port I/O would.
 *
 * Because the exact encoding is board specific and the default offset read
 * back zero during initial investigation, every parameter is tunable and a
 * debugfs probe interface is provided to find the right one.
 *
 * Parameters
 * ----------
 *   offset    EC RAM offset of the tachometer          (default 0x05, = CFAN)
 *   width     1 or 2 bytes                             (default 2)
 *   big_endian  byte order for width=2                 (default false)
 *   divisor   if non-zero, rpm = divisor / raw         (default 0, rpm = raw)
 *   allow_transaction  permit ec_transaction() probes  (default false)
 *
 * debugfs (under /sys/kernel/debug/nuc_ec_fan/)
 * ---------------------------------------------
 *   ecdump        read: hexdump of all 256 EC RAM bytes via ec_read()
 *   altdump       read: hexdump of the secondary EC channel (alt_channel=1)
 *   transaction   write: "<cmd> <rlen> [wbyte ...]" then read back the reply.
 *                 Requires allow_transaction=1.  Issuing arbitrary EC
 *                 commands can change EC state - use only for discovery.
 */

#include <linux/acpi.h>
#include <linux/debugfs.h>
#include <linux/delay.h>
#include <linux/hwmon.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/slab.h>

#define NUC_EC_FAN_NAME		"nuc_ec_fan"
#define NUC_EC_RAM_SIZE		256
#define NUC_EC_XFER_MAX		32

static unsigned int offset = 0x05;
module_param(offset, uint, 0644);
MODULE_PARM_DESC(offset, "EC RAM offset of the fan tachometer (default 0x05)");

static unsigned int width = 2;
module_param(width, uint, 0644);
MODULE_PARM_DESC(width, "tachometer width in bytes, 1 or 2 (default 2)");

static bool big_endian;
module_param(big_endian, bool, 0644);
MODULE_PARM_DESC(big_endian, "treat a 2-byte tachometer as big endian");

static unsigned int divisor;
module_param(divisor, uint, 0644);
MODULE_PARM_DESC(divisor, "if non-zero, rpm = divisor / raw (default 0: rpm = raw)");

static bool allow_transaction;
module_param(allow_transaction, bool, 0644);
MODULE_PARM_DESC(allow_transaction, "allow ec_transaction() probes via debugfs");

/*
 * Secondary EC channel.
 *
 * EC0's _CRS reserves six I/O ports - 0x62/0x66 for the standard ACPI EC
 * that the kernel drives, plus 0x68/0x6C and 0x6A/0x6E.  /proc/ioports
 * shows acpi_ec claiming only 0x62 ("EC data") and 0x66 ("EC cmd"); the
 * other four are reserved by the PNP0C09 device but left unclaimed, so
 * nothing in the kernel drives them.
 *
 * ECCM, the AML field at 0x6E, is polled for an IBF-style busy bit of
 * 0x02 before a command is written, which is the ordinary ACPI EC
 * protocol on a different port pair.  That makes 0x6E the command/status
 * register and 0x6A its data register.
 *
 * Reads here use the standard RD_EC (0x80) command rather than any of the
 * vendor command codes the firmware issues (0x86-0x8B via WECC), which are
 * writes with unknown side effects.
 */
static bool alt_channel;
module_param(alt_channel, bool, 0644);
MODULE_PARM_DESC(alt_channel, "enable the secondary EC channel reader");

static unsigned int alt_cmd = 0x6E;
module_param(alt_cmd, uint, 0644);
MODULE_PARM_DESC(alt_cmd, "secondary channel command/status port (default 0x6E)");

static unsigned int alt_data = 0x6A;
module_param(alt_data, uint, 0644);
MODULE_PARM_DESC(alt_data, "secondary channel data port (default 0x6A)");

static struct dentry *nuc_ec_fan_debugfs;
static DEFINE_MUTEX(nuc_ec_fan_lock);

static u8 xfer_reply[NUC_EC_XFER_MAX];
static unsigned int xfer_reply_len;

static int nuc_ec_fan_read_raw(unsigned int off, unsigned int len, u32 *out)
{
	u8 buf[2] = { 0, 0 };
	unsigned int i;
	int err;

	if (len != 1 && len != 2)
		return -EINVAL;
	if (off + len > NUC_EC_RAM_SIZE)
		return -EINVAL;

	for (i = 0; i < len; i++) {
		err = ec_read(off + i, &buf[i]);
		if (err)
			return err;
	}

	if (len == 1)
		*out = buf[0];
	else if (big_endian)
		*out = (buf[0] << 8) | buf[1];
	else
		*out = (buf[1] << 8) | buf[0];

	return 0;
}

static int nuc_ec_fan_rpm(long *rpm)
{
	u32 raw;
	int err;

	err = nuc_ec_fan_read_raw(offset, width, &raw);
	if (err)
		return err;

	if (!divisor)
		*rpm = raw;
	else if (raw)
		*rpm = divisor / raw;
	else
		*rpm = 0;

	return 0;
}

static umode_t nuc_ec_fan_is_visible(const void *drvdata,
				     enum hwmon_sensor_types type,
				     u32 attr, int channel)
{
	if (type == hwmon_fan && attr == hwmon_fan_input)
		return 0444;

	return 0;
}

static int nuc_ec_fan_hwmon_read(struct device *dev,
				 enum hwmon_sensor_types type,
				 u32 attr, int channel, long *val)
{
	if (type != hwmon_fan || attr != hwmon_fan_input)
		return -EOPNOTSUPP;

	return nuc_ec_fan_rpm(val);
}

static const struct hwmon_channel_info * const nuc_ec_fan_info[] = {
	HWMON_CHANNEL_INFO(fan, HWMON_F_INPUT),
	NULL
};

static const struct hwmon_ops nuc_ec_fan_hwmon_ops = {
	.is_visible = nuc_ec_fan_is_visible,
	.read = nuc_ec_fan_hwmon_read,
};

static const struct hwmon_chip_info nuc_ec_fan_chip_info = {
	.ops = &nuc_ec_fan_hwmon_ops,
	.info = nuc_ec_fan_info,
};

/* ACPI EC status register bits, as used on the standard 0x62/0x66 pair. */
#define EC_SC_OBF		0x01	/* output buffer full - data ready */
#define EC_SC_IBF		0x02	/* input buffer full - EC still busy */
#define EC_CMD_RD_EC		0x80	/* read a byte of EC address space */

#define ALT_POLL_US		10
#define ALT_TIMEOUT_US		10000

static int alt_wait(u8 mask, u8 want)
{
	unsigned int waited = 0;
	u8 sc;

	for (;;) {
		sc = inb(alt_cmd);
		if ((sc & mask) == want)
			return 0;
		if (waited >= ALT_TIMEOUT_US)
			return -ETIMEDOUT;
		udelay(ALT_POLL_US);
		waited += ALT_POLL_US;
	}
}

static int alt_read(u8 addr, u8 *val)
{
	int err;

	err = alt_wait(EC_SC_IBF, 0);
	if (err)
		return err;
	outb(EC_CMD_RD_EC, alt_cmd);

	err = alt_wait(EC_SC_IBF, 0);
	if (err)
		return err;
	outb(addr, alt_data);

	err = alt_wait(EC_SC_OBF, EC_SC_OBF);
	if (err)
		return err;
	*val = inb(alt_data);

	return 0;
}

static int altdump_show(struct seq_file *s, void *unused)
{
	u8 buf[NUC_EC_RAM_SIZE];
	unsigned int i;
	int err;

	if (!alt_channel) {
		seq_puts(s, "disabled - set alt_channel=1 to enable\n");
		return 0;
	}

	seq_printf(s, "# secondary channel cmd=0x%02x data=0x%02x status=0x%02x\n",
		   alt_cmd, alt_data, inb(alt_cmd));

	mutex_lock(&nuc_ec_fan_lock);
	for (i = 0; i < NUC_EC_RAM_SIZE; i++) {
		err = alt_read(i, &buf[i]);
		if (err) {
			mutex_unlock(&nuc_ec_fan_lock);
			seq_printf(s, "alt_read(0x%02x) failed: %d\n", i, err);
			return 0;
		}
	}
	mutex_unlock(&nuc_ec_fan_lock);

	for (i = 0; i < NUC_EC_RAM_SIZE; i += 16)
		seq_printf(s, "%02x: %*ph\n", i, 16, buf + i);

	return 0;
}
DEFINE_SHOW_ATTRIBUTE(altdump);

static int ecdump_show(struct seq_file *s, void *unused)
{
	u8 buf[NUC_EC_RAM_SIZE];
	unsigned int i;
	int err;

	for (i = 0; i < NUC_EC_RAM_SIZE; i++) {
		err = ec_read(i, &buf[i]);
		if (err) {
			seq_printf(s, "ec_read(0x%02x) failed: %d\n", i, err);
			return 0;
		}
	}

	for (i = 0; i < NUC_EC_RAM_SIZE; i += 16)
		seq_printf(s, "%02x: %*ph\n", i, 16, buf + i);

	return 0;
}
DEFINE_SHOW_ATTRIBUTE(ecdump);

static ssize_t transaction_write(struct file *file, const char __user *ubuf,
				 size_t count, loff_t *ppos)
{
	unsigned int cmd, rlen, wbyte;
	u8 wdata[NUC_EC_XFER_MAX];
	unsigned int wlen = 0;
	char *line, *p, *tok;
	int err;

	if (!allow_transaction)
		return -EPERM;
	if (count > PAGE_SIZE)
		return -EINVAL;

	line = memdup_user_nul(ubuf, count);
	if (IS_ERR(line))
		return PTR_ERR(line);

	p = strim(line);
	tok = strsep(&p, " \t");
	if (!tok || kstrtouint(tok, 0, &cmd) || cmd > 0xff) {
		err = -EINVAL;
		goto out;
	}

	tok = strsep(&p, " \t");
	if (!tok || kstrtouint(tok, 0, &rlen) || rlen > NUC_EC_XFER_MAX) {
		err = -EINVAL;
		goto out;
	}

	while ((tok = strsep(&p, " \t")) && wlen < NUC_EC_XFER_MAX) {
		if (!*tok)
			continue;
		if (kstrtouint(tok, 0, &wbyte) || wbyte > 0xff) {
			err = -EINVAL;
			goto out;
		}
		wdata[wlen++] = wbyte;
	}

	mutex_lock(&nuc_ec_fan_lock);
	memset(xfer_reply, 0, sizeof(xfer_reply));
	err = ec_transaction(cmd, wlen ? wdata : NULL, wlen,
			     rlen ? xfer_reply : NULL, rlen);
	xfer_reply_len = err ? 0 : rlen;
	mutex_unlock(&nuc_ec_fan_lock);

	if (err) {
		pr_warn(NUC_EC_FAN_NAME ": ec_transaction(0x%02x) failed: %d\n",
			cmd, err);
		goto out;
	}

	err = count;
out:
	kfree(line);
	return err;
}

static int transaction_show(struct seq_file *s, void *unused)
{
	mutex_lock(&nuc_ec_fan_lock);
	if (xfer_reply_len)
		seq_printf(s, "%*ph\n", xfer_reply_len, xfer_reply);
	else
		seq_puts(s, "(no reply - write \"<cmd> <rlen> [wbyte ...]\" first)\n");
	mutex_unlock(&nuc_ec_fan_lock);

	return 0;
}

static int transaction_open(struct inode *inode, struct file *file)
{
	return single_open(file, transaction_show, inode->i_private);
}

static const struct file_operations transaction_fops = {
	.owner   = THIS_MODULE,
	.open    = transaction_open,
	.read    = seq_read,
	.write   = transaction_write,
	.llseek  = seq_lseek,
	.release = single_release,
};

static struct platform_device *nuc_ec_fan_pdev;

static int __init nuc_ec_fan_init(void)
{
	struct device *hwmon;
	long rpm;
	int err;

	if (width != 1 && width != 2)
		return -EINVAL;
	if (offset + width > NUC_EC_RAM_SIZE)
		return -EINVAL;

	/* Fail early and loudly if there is no usable EC rather than
	 * registering a hwmon device that can only ever return errors.
	 */
	err = nuc_ec_fan_rpm(&rpm);
	if (err) {
		pr_err(NUC_EC_FAN_NAME ": EC read at 0x%02x failed: %d\n",
		       offset, err);
		return err;
	}

	/* hwmon_device_register_with_info() rejects a NULL parent when a
	 * chip_info is supplied, so anchor the sensor on a platform device.
	 */
	nuc_ec_fan_pdev = platform_device_register_simple(NUC_EC_FAN_NAME, -1,
							  NULL, 0);
	if (IS_ERR(nuc_ec_fan_pdev))
		return PTR_ERR(nuc_ec_fan_pdev);

	hwmon = devm_hwmon_device_register_with_info(&nuc_ec_fan_pdev->dev,
						     NUC_EC_FAN_NAME, NULL,
						     &nuc_ec_fan_chip_info,
						     NULL);
	if (IS_ERR(hwmon)) {
		platform_device_unregister(nuc_ec_fan_pdev);
		return PTR_ERR(hwmon);
	}

	nuc_ec_fan_debugfs = debugfs_create_dir(NUC_EC_FAN_NAME, NULL);
	debugfs_create_file("ecdump", 0400, nuc_ec_fan_debugfs, NULL,
			    &ecdump_fops);
	debugfs_create_file("transaction", 0600, nuc_ec_fan_debugfs, NULL,
			    &transaction_fops);
	debugfs_create_file("altdump", 0400, nuc_ec_fan_debugfs, NULL,
			    &altdump_fops);

	pr_info(NUC_EC_FAN_NAME ": offset 0x%02x width %u reads %ld rpm\n",
		offset, width, rpm);

	return 0;
}

static void __exit nuc_ec_fan_exit(void)
{
	debugfs_remove_recursive(nuc_ec_fan_debugfs);
	platform_device_unregister(nuc_ec_fan_pdev);
}

module_init(nuc_ec_fan_init);
module_exit(nuc_ec_fan_exit);

MODULE_DESCRIPTION("Intel NUC embedded-controller fan tachometer");
MODULE_LICENSE("GPL");
