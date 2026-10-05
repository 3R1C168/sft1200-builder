#!/usr/bin/env bash
# 把 board/ 五件套 overlay 进 Siflower SDK 源码树。用法: apply-board.sh <sdk-root>
set -euo pipefail
SDK="$(cd "$1" && pwd)"
OW="$SDK/openwrt-18.06"
TGT="$OW/target/linux/siflower"
KDT="$SDK/linux-4.14.90-dev/linux-4.14.90/arch/mips/boot/dts/siflower"
B="$(cd "$(dirname "$0")/.." && pwd)/board"

for d in "$OW" "$TGT/sf19a28-fullmask" "$KDT"; do
  [ -d "$d" ] || { echo "FATAL: SDK path missing: $d"; exit 1; }
done

cp "$B/sf19a28_gl_sft1200_fullmask_def.config"   "$TGT/"
cp "$B/config-4.14_gl_sft1200"                   "$TGT/sf19a28-fullmask/"
mkdir -p "$TGT/sf19a28-fullmask/profiles"
cp "$B/profiles/sf19a28-gl-sft1200.mk"           "$TGT/sf19a28-fullmask/profiles/"
cp -a "$B/base-files-SF19A28-GL-SFT1200"         "$TGT/sf19a28-fullmask/"
cp "$B/dts/sf19a28_fullmask_gl_sft1200.dts"      "$KDT/"

# 内核 DTS Makefile 是逐板列表:追加 GL_SFT1200 行(幂等)
LINE='dtb-$(CONFIG_DT_SF19A28_FULLMASK_GL_SFT1200)\t+= sf19a28_fullmask_gl_sft1200.dtb'
if ! grep -q 'GL_SFT1200' "$KDT/Makefile"; then
  sed -i "/ROUTER_1211/a $LINE" "$KDT/Makefile"
fi

echo "== overlay done =="
grep -n 'GL_SFT1200' "$KDT/Makefile"
ls "$TGT/sf19a28-fullmask/" | grep -i gl_sft1200

if [ -d "$B/theme/luci-theme-argon" ]; then
  mkdir -p "$OW/package/theme"
  cp -a "$B/theme/luci-theme-argon" "$OW/package/theme/"
  echo "copied argon theme to package/theme/"
fi
