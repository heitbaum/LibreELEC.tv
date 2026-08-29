#!/bin/sh
# Runs on the LibreELEC host that carries the die, not on the build host.
# Download a boot image into the rk1808 die, reliably.
#
#   dieboot.sh <image-in-/storage/.config/npu>
#
# The service alone is not enough after repeated cycles: it powers the die by
# rebinding onboard-usb-dev and gives up after a short wait, and the die then
# reports "did not reach maskrom" even though nothing is wrong with the image.
# It needs about ten seconds unbound before it will come back. Three images were
# blamed on a driver before this turned out to be the cause, so always confirm
# 2207:180a here before concluding anything about what is being booted.
N=/storage/.config/npu
DRV=/sys/bus/platform/drivers/onboard-usb-dev
DEV=fe900000.usb:device@1

[ -f "$N/$1" ] || { echo "  no such image: $N/$1"; exit 1; }
cp "$N/$1" "$N/boot.img"
echo "  booting $1"

npu_id() {
  for d in /sys/bus/usb/devices/[0-9]*-[0-9]*; do
    [ -f "$d/idVendor" ] || continue
    [ "$(cat $d/idVendor)" = "2207" ] && cat "$d/idProduct" && return 0
  done
  return 1
}

systemctl stop rk3399pro-npu >/dev/null 2>&1
echo "$DEV" > $DRV/unbind 2>/dev/null
sleep 10
echo "$DEV" > $DRV/bind 2>/dev/null

i=0
while [ $i -lt 12 ]; do
  sleep 5
  [ "$(npu_id 2>/dev/null)" = "180a" ] && break
  i=$((i + 1))
done
[ "$(npu_id 2>/dev/null)" = "180a" ] || { echo "  never reached maskrom"; exit 1; }
echo "  maskrom"

systemctl start rk3399pro-npu >/dev/null 2>&1
i=0
while [ $i -lt 12 ]; do
  sleep 5
  [ "$(npu_id 2>/dev/null)" = "1808" ] && break
  i=$((i + 1))
done
[ "$(npu_id 2>/dev/null)" = "1808" ] || { echo "  never reached runtime"; exit 1; }

for d in /sys/bus/usb/devices/[0-9]*-[0-9]*; do
  [ -f "$d/idVendor" ] || continue
  [ "$(cat $d/idVendor)" = "2207" ] || continue
  echo "  runtime on $(basename $d): speed $(cat $d/speed) usb $(cat $d/version | tr -d ' ')"
done

# the installed service script predates npu_net, so the host end of the rndis
# link has to be addressed by hand or the die shell is unreachable
ip addr add 10.42.0.100/24 dev usb0 2>/dev/null
sleep 2
ping -c2 -W2 10.42.0.1 >/dev/null 2>&1 && echo "  die shell reachable" || echo "  no die network"
