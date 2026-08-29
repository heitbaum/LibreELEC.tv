#!/bin/sh
# Runs on the LibreELEC host that carries the die, not on the build host.
# Run one command on the rk1808 die and print what it says.
#
# The die has no ssh and no persistent storage - its shell is busybox on
# telnet 10.42.0.1. Commands are fed in with sleeps because there is no way to
# know when the remote shell is ready to read, and the session ends on EOF.
#
# Two traps, both of which cost time to find:
#
#   - telnet terminates lines with CRLF and this busybox leaves the CR on the
#     last token, so a command ENDING in a numeric argument fails:
#         tail -n 25         -> tail: invalid number '25'
#         tail -n 25 ; true  -> works
#     The CR arrives from the transport, after this script, so stripping it
#     here does nothing. Appending a no-op keeps real arguments off the end.
#
#   - this busybox tail has no -NUM form. Use -n NUM.
#
# Do not set PATH: the die's own /sbin:/usr/sbin:/bin:/usr/bin is correct, and
# there is no separate dmesg binary - call "busybox dmesg".
{
  sleep 2
  echo "$* ; true"
  sleep 6
} | telnet 10.42.0.1 2>/dev/null
