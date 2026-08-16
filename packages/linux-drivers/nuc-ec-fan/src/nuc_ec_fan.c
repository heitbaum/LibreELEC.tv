// SPDX-License-Identifier: GPL-2.0-only
/*
 * nuc_ec_fan - Intel NUC embedded-controller fan tachometer and temperature
 *
 * NUC12 (Wall Street Canyon) publishes no fan speed by any of the routes a
 * driver would normally use.  There is no Super-I/O sensor chip, the ACPI
 * fan objects under \_TZ_ are legacy on/off cooling devices with no _FPS,
 * and the firmware's own sensor interface at \_SB.PTID.OSDD is gated on
 * \_SB.PC00.LPCB.H_EC.ECAV, which is never set because that EC device
 * reports _STA = 0.  The DSDT declares no EmbeddedControl operation region
 * at all, so there is no AML-described EC address map either, and the
 * tachometer is not in the EC address space the kernel drives - a dump at
 * 100 C with the fan running is identical to an idle one apart from the
 * temperature byte.
 *
 * What the firmware actually uses is a memory mapped window, declared in
 * the DSDT as
 *
 *   OperationRegion(ERAM, SystemMemory, 0xFE410400, 0x0200)
 *
 * It begins with the ASCII signature "NUC_EC" and carries the live sensor
 * values.  The tachometer is a big endian u16 which the EC mirrors at two
 * offsets, 0x1D and 0x70:
 *
 *   idle, fan at its floor : 0x03FA = 1018 rpm
 *   full load at 100 C     : 0x1227 = 4647 rpm
 *
 * which agrees with the 4278 rpm the BIOS reports at 98 C on a gentler fan
 * curve.  CPU temperature in degrees C sits at 0x0E, mirrored at 0x62.
 *
 * Reading is a plain MMIO load from a window no driver claims, so this
 * needs no EC transactions and cannot race the ACPI EC driver.
 */

#include <linux/debugfs.h>
#include <linux/hwmon.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/platform_device.h>

#define NUC_EC_FAN_NAME		"nuc_ec_fan"
#define NUC_EC_SIGNATURE	"NUC_EC"
#define NUC_EC_SIG_LEN		6

static unsigned long mmio_base = 0xFE410400;
module_param(mmio_base, ulong, 0444);
MODULE_PARM_DESC(mmio_base, "physical base of the NUC_EC window (default 0xFE410400)");

static unsigned int mmio_len = 0x200;
module_param(mmio_len, uint, 0444);
MODULE_PARM_DESC(mmio_len, "length of the NUC_EC window (default 0x200)");

static unsigned int rpm_offset = 0x1D;
module_param(rpm_offset, uint, 0644);
MODULE_PARM_DESC(rpm_offset, "offset of the big endian u16 tachometer (default 0x1D)");

static unsigned int temp_offset = 0x0E;
module_param(temp_offset, uint, 0644);
MODULE_PARM_DESC(temp_offset, "offset of the CPU temperature byte (default 0x0E)");

static bool force;
module_param(force, bool, 0444);
MODULE_PARM_DESC(force, "bind even if the NUC_EC signature is absent");

static void __iomem *nuc_ec_win;
static struct platform_device *nuc_ec_fan_pdev;
static struct dentry *nuc_ec_fan_debugfs;

static long nuc_ec_fan_rpm(void)
{
	/* Big endian: high byte first, as the EC stores it. */
	return (ioread8(nuc_ec_win + rpm_offset) << 8) |
		ioread8(nuc_ec_win + rpm_offset + 1);
}

static long nuc_ec_fan_temp(void)
{
	return ioread8(nuc_ec_win + temp_offset) * 1000;
}

static umode_t nuc_ec_fan_is_visible(const void *drvdata,
				     enum hwmon_sensor_types type,
				     u32 attr, int channel)
{
	if (type == hwmon_fan && attr == hwmon_fan_input)
		return 0444;
	if (type == hwmon_temp && attr == hwmon_temp_input)
		return 0444;

	return 0;
}

static int nuc_ec_fan_read(struct device *dev, enum hwmon_sensor_types type,
			   u32 attr, int channel, long *val)
{
	switch (type) {
	case hwmon_fan:
		*val = nuc_ec_fan_rpm();
		return 0;
	case hwmon_temp:
		*val = nuc_ec_fan_temp();
		return 0;
	default:
		return -EOPNOTSUPP;
	}
}

static const char * const nuc_ec_fan_labels[] = { "CPU Fan" };
static const char * const nuc_ec_temp_labels[] = { "EC CPU Temp" };

static int nuc_ec_fan_read_string(struct device *dev,
				  enum hwmon_sensor_types type,
				  u32 attr, int channel, const char **str)
{
	if (type == hwmon_fan && attr == hwmon_fan_label)
		*str = nuc_ec_fan_labels[0];
	else if (type == hwmon_temp && attr == hwmon_temp_label)
		*str = nuc_ec_temp_labels[0];
	else
		return -EOPNOTSUPP;

	return 0;
}

static const struct hwmon_channel_info * const nuc_ec_fan_info[] = {
	HWMON_CHANNEL_INFO(fan, HWMON_F_INPUT | HWMON_F_LABEL),
	HWMON_CHANNEL_INFO(temp, HWMON_T_INPUT | HWMON_T_LABEL),
	NULL
};

static const struct hwmon_ops nuc_ec_fan_hwmon_ops = {
	.is_visible = nuc_ec_fan_is_visible,
	.read = nuc_ec_fan_read,
	.read_string = nuc_ec_fan_read_string,
};

static const struct hwmon_chip_info nuc_ec_fan_chip_info = {
	.ops = &nuc_ec_fan_hwmon_ops,
	.info = nuc_ec_fan_info,
};

static int ecwin_show(struct seq_file *s, void *unused)
{
	unsigned int i;
	u8 buf[16];

	for (i = 0; i < mmio_len; i += 16) {
		unsigned int j;

		for (j = 0; j < 16; j++)
			buf[j] = ioread8(nuc_ec_win + i + j);
		seq_printf(s, "%03x: %*ph\n", i, 16, buf);
	}

	return 0;
}
DEFINE_SHOW_ATTRIBUTE(ecwin);

static int __init nuc_ec_fan_init(void)
{
	char sig[NUC_EC_SIG_LEN + 1] = { };
	struct device *hwmon;
	unsigned int i;
	int err;

	if (rpm_offset + 1 >= mmio_len || temp_offset >= mmio_len)
		return -EINVAL;

	nuc_ec_win = ioremap(mmio_base, mmio_len);
	if (!nuc_ec_win)
		return -ENOMEM;

	for (i = 0; i < NUC_EC_SIG_LEN; i++)
		sig[i] = ioread8(nuc_ec_win + i);

	if (memcmp(sig, NUC_EC_SIGNATURE, NUC_EC_SIG_LEN)) {
		pr_err(NUC_EC_FAN_NAME ": no \"%s\" signature at 0x%lx (found \"%s\")\n",
		       NUC_EC_SIGNATURE, mmio_base, sig);
		if (!force) {
			err = -ENODEV;
			goto err_unmap;
		}
	}

	nuc_ec_fan_pdev = platform_device_register_simple(NUC_EC_FAN_NAME, -1,
							  NULL, 0);
	if (IS_ERR(nuc_ec_fan_pdev)) {
		err = PTR_ERR(nuc_ec_fan_pdev);
		goto err_unmap;
	}

	hwmon = devm_hwmon_device_register_with_info(&nuc_ec_fan_pdev->dev,
						     NUC_EC_FAN_NAME, NULL,
						     &nuc_ec_fan_chip_info,
						     NULL);
	if (IS_ERR(hwmon)) {
		err = PTR_ERR(hwmon);
		goto err_pdev;
	}

	nuc_ec_fan_debugfs = debugfs_create_dir(NUC_EC_FAN_NAME, NULL);
	debugfs_create_file("ecwin", 0400, nuc_ec_fan_debugfs, NULL,
			    &ecwin_fops);

	pr_info(NUC_EC_FAN_NAME ": %s at 0x%lx, fan %ld rpm, cpu %ld C\n",
		sig, mmio_base, nuc_ec_fan_rpm(), nuc_ec_fan_temp() / 1000);

	return 0;

err_pdev:
	platform_device_unregister(nuc_ec_fan_pdev);
err_unmap:
	iounmap(nuc_ec_win);
	return err;
}

static void __exit nuc_ec_fan_exit(void)
{
	debugfs_remove_recursive(nuc_ec_fan_debugfs);
	platform_device_unregister(nuc_ec_fan_pdev);
	iounmap(nuc_ec_win);
}

module_init(nuc_ec_fan_init);
module_exit(nuc_ec_fan_exit);

MODULE_DESCRIPTION("Intel NUC embedded-controller fan tachometer");
MODULE_LICENSE("GPL");
