# sft1200-builder

GL.iNet GL-SFT1200 (Opal) 基于官方 Siflower SDK 与官方板级文件的自动化构建固件。

- **GitHub Release 下载**: [v1.0.0 最新固件发布页面](https://github.com/3R1C168/sft1200-builder/releases)
- **设计文档**: [docs/superpowers/specs/](docs/superpowers/specs/)
- **实施计划**: [docs/superpowers/plans/](docs/superpowers/plans/)

---

## 固件特性

1. **纯正开源与官方来源**:
   - 源码底包: 矽昌官方 [Siflower/1806_SDK](https://github.com/Siflower/1806_SDK) (`release2.0.0` / Linux 4.14.90)
   - 板级支持: GL.iNet 官方 [gl-inet-builder/openwrt-imagebuilder-siflower-sf19a28-nand_3.8](https://github.com/gl-inet-builder/openwrt-imagebuilder-siflower-sf19a28-nand_3.8) 提取的 SFT1200 NAND 专用五件套（DTS、机型 Profile、内核配置、出厂网络脚本）
   - 无线驱动: 矽昌原厂 Wi-Fi 驱动（`sf_smac`，2.4G & 5G 满血硬件加速与 AP 支持）
2. **原生 LuCI + 内置 Argon 主题**:
   - 移除 GL 官方闭源应用与商业 UI，开机直接进入纯净的原生 OpenWrt LuCI 后台。
   - 内置适配 18.06 的 [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon)，现代暗色自适应风格。
3. **针对现代编译器适配**:
   - 包含多项针对 Ubuntu 22.04 / GCC 11 / Glibc 2.35 的宿主工具链与内核语法兼容性补丁。

---

## 刷机指南

### 方式一: U-Boot 救砖模式刷入（最推荐，零风险）

1. 电脑网线连接 SFT-1200 的 **LAN 口**。
2. 将电脑网卡 IP 手动配置为静态：`192.168.1.2`，子网掩码 `255.255.255.0`，网关 `192.168.1.1`。
3. 路由器断电，用卡针按住 **Reset 键**不放，插上电源。
4. 观察电源指示灯蓝白闪烁约 5 次后松开 Reset 键。
5. 浏览器打开 `http://192.168.1.1`，进入 U-Boot Web 恢复页面。
6. 选择下载的固件 `openwrt-sft1200-sysupgrade.bin`，点击更新，等待约 3 分钟自动重启完成。

### 方式二: SSH 命令行快速刷入

1. 将下载的 `openwrt-sft1200-sysupgrade.bin` 传输至路由器 `/tmp/` 目录：
   ```bash
   scp openwrt-sft1200-sysupgrade.bin root@192.168.8.1:/tmp/
   ```
2. SSH 登录路由器执行刷写：
   ```bash
   mtd -r write /tmp/openwrt-sft1200-sysupgrade.bin firmware
   ```

---

## 默认网络与登录信息

- **管理后台**: `http://192.168.1.1`
- **默认用户**: `root`
- **默认密码**: 无密码（首次登录直接回车，进入后台后请立即设置密码）
- **默认 Wi-Fi**: 默认开启，详情请登录后台「网络 -> 无线」查看与设置 SSID/密码。

---

## 开源许可

- Siflower SDK: MIT 协议
- Linux 内核及 OpenWrt 组件: GPL-2.0 协议
- 本项目构建脚本与补丁: MIT 协议
