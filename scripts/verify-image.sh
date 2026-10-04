#!/usr/bin/env bash
# 校验编译产物:factory + sysupgrade 双格式存在、尺寸合理。用法: verify-image.sh <openwrt-18.06>
set -euo pipefail
OW="$(cd "$1" && pwd)"
BIN="$OW/bin/targets/siflower"
[ -d "$BIN" ] || { echo "FAIL: $BIN missing"; exit 1; }

echo "== all images =="
find "$BIN" -type f \( -name '*.img' -o -name '*.tar' -o -name '*.bin' \) -printf '%10s  %P\n' | sort -k2

factory="$(find "$BIN" -type f -name '*factory*' | head -1)"
sysup="$(find "$BIN" -type f \( -name '*sysupgrade*' \) | head -1)"
[ -n "$factory" ] || { echo "FAIL: no factory image"; exit 1; }
[ -n "$sysup" ]   || { echo "FAIL: no sysupgrade image"; exit 1; }

fsz="$(stat -c%s "$factory")"
[ "$fsz" -gt 8388608 ] && [ "$fsz" -lt 134217728 ] || { echo "FAIL: factory size $fsz out of range"; exit 1; }

# 命名须可识别机型(SF19A28-GL-SFT1200 profile 的 IMG_PREFIX 规则)
find "$BIN" -type f -printf '%f\n' | grep -qiE 'gl.?sft1200' || {
  echo "FAIL: image name does not reference SFT1200 model"; exit 1; }

echo "OK: factory=$factory ($fsz bytes)"
echo "OK: sysupgrade=$sysup"
