#!/bin/bash
# Apply our changes to the extracted rootfs, idempotently.
#
#   - galcore built for the kernel we build, replacing the shipped one
#   - a usb network function alongside ffs.ntb, so the host gets an interface
#   - a static link-local address and inetd serving a shell on it
#
# The npu keeps working: rndis is added to the same gadget config beside ntb
# rather than replacing it.
#
# rndis rather than ncm or ecm - ncm oopses composite_setup on this gadget
# stack, and rndis is the only network function rk1808_linux_defconfig enables,
# so it is the one rockchip actually test here.
#
# Two rootfs layouts are supported. The 2019 image builds its gadget in
# start_usb.sh, called from S99NPU_init. The 2022 image from
# airockchip/RK3399Pro_npu uses S50usbdevice, which reads .usb_config and
# assembles the gadget from flags - it still ships start_usb.sh but nothing
# calls it.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R="${ROOTFS:-$ROOT/rootfs}"
V="$ROOT/vendor"

[ -d "$R" ] || { echo "no rootfs at $R" >&2; exit 1; }
echo "  rootfs: $R"

# --- galcore matching the kernel we build -----------------------------------
# The 2019 and 2022 images put it in different places.
for d in "$R/usr/lib/modules" "$R/lib/modules"; do
  if [ -f "$d/galcore.ko" ]; then
    cp "$V/galcore.ko" "$d/galcore.ko"
    echo "  galcore -> $d ($(strings "$d/galcore.ko" | grep -m1 ^vermagic))"
  fi
done

# --- the shell we serve on the link -----------------------------------------
cat > "$R/usr/bin/start_netshell.sh" <<'SH'
#!/bin/sh
# Wait for the interface rndis creates, address it, and serve a shell on it.
# 10.42.0.0/24 stays clear of the lan the host sits on.
for i in $(seq 1 30); do
    [ -d /sys/class/net/usb0 ] && break
    sleep 1
done
[ -d /sys/class/net/usb0 ] || exit 0
ifconfig usb0 10.42.0.1 netmask 255.255.255.0 up
inetd /etc/inetd.conf
SH
chmod 755 "$R/usr/bin/start_netshell.sh"

cat > "$R/etc/inetd.conf" <<'CONF'
# raw tcp shell - busybox has inetd but no telnetd, and this needs no new binary
23 stream tcp nowait root /bin/sh sh -i
CONF
chmod 644 "$R/etc/inetd.conf"
echo "  start_netshell.sh + inetd.conf installed"

# --- the gadget -------------------------------------------------------------
if [ -f "$R/etc/init.d/S50usbdevice" ]; then
  echo "  layout: S50usbdevice (2022)"

  # ask for ntb and rndis, drop adb - we do not use adbd and it costs a daemon
  printf 'usb_ntb_en\nusb_rndis_en\n' > "$R/etc/init.d/.usb_config"

  python3 - "$R/etc/init.d/S50usbdevice" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()

if "RNDIS_EN" not in s:
    # a flag for it, alongside the others
    s = s.replace("NTB_EN=off\n", "NTB_EN=off\nRNDIS_EN=off\n", 1)

    # parse usb_rndis_en out of .usb_config
    old = """			usb_acm_en)"""
    new = """			usb_rndis_en)
				RNDIS_EN=on
				make_config_string rndis
				;;
			usb_acm_en)"""
    assert s.count(old) == 1, "acm case"
    s = s.replace(old, new, 1)

    # the case table has no ntb entry at all, so every ntb combination falls
    # through to the 0x0019 default. Our host service looks for 1808, which is
    # what start_usb.sh used in the 2019 image, so name it explicitly.
    old = """		*)
			PID=0x0019"""
    new = """		ntb | ntb_rndis | rndis_ntb)
			PID=0x1808
			;;
		*)
			PID=0x0019"""
    assert s.count(old) == 1, "pid default"
    s = s.replace(old, new, 1)

    # create and link the function, next to ntb
    old = """	if [ $ACM_EN = on ];then
		mkdir ${USB_FUNCTIONS_DIR}/acm.gs6"""
    new = """	if [ $RNDIS_EN = on ];then
		mkdir ${USB_FUNCTIONS_DIR}/rndis.usb0
		echo "0a:1e:08:08:00:01" > ${USB_FUNCTIONS_DIR}/rndis.usb0/dev_addr 2>/dev/null
		echo "0a:1e:08:08:00:02" > ${USB_FUNCTIONS_DIR}/rndis.usb0/host_addr 2>/dev/null
		ln -s ${USB_FUNCTIONS_DIR}/rndis.usb0 ${USB_CONFIGS_DIR}/rndis.usb0
	fi

	if [ $ACM_EN = on ];then
		mkdir ${USB_FUNCTIONS_DIR}/acm.gs6"""
    assert s.count(old) == 1, "acm function"
    s = s.replace(old, new, 1)

    # bring the link up once the gadget is bound
    old = """	UDC=`ls /sys/class/udc/| awk '{print $1}'`
	echo $UDC > ${USB_CONFIGFS_DIR}/UDC
	;;"""
    new = """	UDC=`ls /sys/class/udc/| awk '{print $1}'`
	echo $UDC > ${USB_CONFIGFS_DIR}/UDC

	if [ $RNDIS_EN = on ];then
		start_netshell.sh &
	fi
	;;"""
    assert s.count(old) == 1, "udc write"
    s = s.replace(old, new, 1)

    open(p, "w").write(s)
    print("  S50usbdevice: rndis added, ntb pid set to 0x1808, netshell called")
else:
    print("  S50usbdevice: already patched")
PY

else
  echo "  layout: start_usb.sh (2019)"

  G="$R/usr/bin/start_usb.sh"
  if ! grep -q "rndis.usb0" "$G"; then
    python3 - "$G" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = """    configfs_init 0x1808 ntb
    function_init ntb
"""
new = """    configfs_init 0x1808 ntb
    function_init ntb

    # a network function beside ntb, so the host can reach a shell here.
    # linked before rknn_server writes the UDC. The addresses are set before
    # it binds; rndis derives its own if they are left empty, but fixing them
    # keeps the host end predictable across reflashes.
    RN=/sys/kernel/config/usb_gadget/rockchip/functions/rndis.usb0
    mkdir -p $RN
    echo "0a:1e:08:08:00:01" > $RN/dev_addr 2>/dev/null
    echo "0a:1e:08:08:00:02" > $RN/host_addr 2>/dev/null
    ln -sf $RN /sys/kernel/config/usb_gadget/rockchip/configs/b.1/rndis.usb0
"""
assert s.count(old) == 1, "start_usb.sh anchor"
open(p, "w").write(s.replace(old, new))
PY
    echo "  start_usb.sh: rndis.usb0 added to the ntb config"
  fi

  N="$R/etc/init.d/S99NPU_init"
  if ! grep -q start_netshell "$N"; then
    sed -i 's|^\t\tstart_usb.sh ntb$|\t\tstart_usb.sh ntb\n\t\tstart_netshell.sh \&|' "$N"
    grep -q start_netshell "$N" || { echo "  ERROR: S99NPU_init anchor missed" >&2; exit 1; }
    echo "  S99NPU_init: start_netshell.sh called after start_usb.sh"
  fi
fi
