#!/usr/bin/env bash
# 校验编译产物: sysupgrade 镜像存在且尺寸合理。用法: verify-image.sh <openwrt-18.06>
set -euo pipefail
OW="$(cd "$1" && pwd)"
BIN="$OW/bin/targets/siflower"
[ -d "$BIN" ] || { echo "FAIL: $BIN missing"; exit 1; }

echo "== all images =="
find "$BIN" -maxdepth 2 -type f \( -name '*.img' -o -name '*.tar' -o -name '*.bin' \) -printf '%10s  %P
' | sort -k2

sysup="$(find "$BIN" -maxdepth 2 -type f -name '*sysupgrade.bin' | head -1)"
[ -n "$sysup" ] || { echo "FAIL: no sysupgrade image"; exit 1; }

fsz="$(stat -c%s "$sysup")"
[ "$fsz" -gt 8388608 ] && [ "$fsz" -lt 134217728 ] || { echo "FAIL: sysupgrade size $fsz out of range"; exit 1; }

echo "OK: sysupgrade=$sysup ($fsz bytes)"
