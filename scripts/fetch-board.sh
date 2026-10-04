#!/usr/bin/env bash
# 从 GL 官方 imagebuilder 仓库拉取 SFT1200 板级文件(五件套,共 13 个文件)
set -euo pipefail
R="https://raw.githubusercontent.com/gl-inet-builder/openwrt-imagebuilder-siflower-sf19a28-nand_3.8/main"
B="$(cd "$(dirname "$0")/.." && pwd)/board"
mkdir -p "$B/profiles" "$B/dts" \
  "$B/base-files-SF19A28-GL-SFT1200/bin" \
  "$B/base-files-SF19A28-GL-SFT1200/etc/board.d" \
  "$B/base-files-SF19A28-GL-SFT1200/usr/bin"

dl() { # dl <remote-path> <local-rel-path>
  echo "GET $1"
  curl -fsSL --retry 3 "$R/$1" -o "$B/$2"
}

dl target/linux/siflower/sf19a28_gl_sft1200_fullmask_def.config  sf19a28_gl_sft1200_fullmask_def.config
dl target/linux/siflower/sf19a28-fullmask/config-4.14_gl_sft1200 config-4.14_gl_sft1200
dl target/linux/siflower/sf19a28-fullmask/profiles/sf19a28-gl-sft1200.mk profiles/sf19a28-gl-sft1200.mk
dl build_dir/target-mipsel_mips-interAptiv_musl/linux-siflower_sf19a28-fullmask/linux-4.14.90/arch/mips/boot/dts/siflower/sf19a28_fullmask_gl_sft1200.dts dts/sf19a28_fullmask_gl_sft1200.dts
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/bin/config_check.sh        base-files-SF19A28-GL-SFT1200/bin/config_check.sh
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/bin/sf_reset.sh            base-files-SF19A28-GL-SFT1200/bin/sf_reset.sh
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/bin/wanLinkStatus          base-files-SF19A28-GL-SFT1200/bin/wanLinkStatus
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/etc/board.d/01_network     base-files-SF19A28-GL-SFT1200/etc/board.d/01_network
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/etc/board.d/99-default_network base-files-SF19A28-GL-SFT1200/etc/board.d/99-default_network
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/etc/rc.local               base-files-SF19A28-GL-SFT1200/etc/rc.local
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/usr/bin/hnat_enable.sh     base-files-SF19A28-GL-SFT1200/usr/bin/hnat_enable.sh
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/usr/bin/hnat_read.sh       base-files-SF19A28-GL-SFT1200/usr/bin/hnat_read.sh
dl target/linux/siflower/sf19a28-fullmask/base-files-SF19A28-GL-SFT1200/usr/bin/hnat_update_interface.sh base-files-SF19A28-GL-SFT1200/usr/bin/hnat_update_interface.sh

echo "== downloaded =="
find "$B" -type f ! -name SOURCES.md -printf "%s\t%P\n" | sort
