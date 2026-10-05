#!/usr/bin/env bash
# 生成 .config:SFT1200 官方 def.config 为底,叠加 LuCI。用法: gen-config.sh <openwrt-18.06>
set -euo pipefail
OW="$(cd "$1" && pwd)"
[ -f "$OW/target/linux/siflower/sf19a28_gl_sft1200_fullmask_def.config" ] || {
  echo "FATAL: def.config not found - run apply-board.sh first"; exit 1; }

cp "$OW/target/linux/siflower/sf19a28_gl_sft1200_fullmask_def.config" "$OW/.config"
cat >> "$OW/.config" <<'EOF'
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-theme-argon=y
EOF
make -C "$OW" defconfig
echo "== .config generated =="
grep -E 'CONFIG_PACKAGE_luci=|CONFIG_TARGET_BOARD|CONFIG_TARGET_SUBTARGET' "$OW/.config"
