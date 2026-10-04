# GL.iNet SFT1200 GitHub Actions 自建固件编译 — 设计文档

日期:2026-10-05
状态:待用户审阅

## 1. 背景与目标

GL.iNet SFT1200(Opal)路由器,SoC 为矽昌 Siflower SF19A28(双核 MIPS,WiFi 5,128MB NAND)。官方 WiFi 驱动只兼容矽昌 OpenWrt 18.06 SDK(内核 4.14.90);主线 OpenWrt / ImmortalWrt(kernel 6.18)无 WiFi 驱动,移植为数月级内核开发,放弃。

**目标**:新建一个 GitHub 仓库,用 GitHub Actions 云端编译 SFT1200 固件:

- 源码与板级文件**全部来自官方/原厂公开仓库**(矽昌 `Siflower/1806_SDK` + GL.iNet `gl-inet-builder` 组织),不使用社区作者 wekingchen 的任何私有文件。
- **UI 策略(用户 2026-10-05 确认)**:固件默认且唯一的 Web UI 为 LuCI(GL 官方 UI 为闭源,不在任何源码来源中,自编译固件天然没有它,无需"手动开启");不移植 GL 闭源应用,官方功能用 LuCI 生态等价 luci-app 替代(映射表见 §8)。
- 固件含**官方 WiFi 驱动** + LuCI 管理界面。
- 插件(opkg 包)支持增量添加;第一版只做最小可用集,完整清单由用户后续提供(见 §8)。

**用户已确认的决策**:

| 决策点 | 结论 |
|---|---|
| 系统底子 | 接受 18.06 / 内核 4.14(用户 2026-10-05 确认) |
| 路线 | 甲·纯官方自建,不碰 wekingchen 任何文件(用户选定) |
| 插件清单 | 用户后定;第一版最小集先打通流水线 |

## 2. 已核实的关键事实(调查结论,2026-10-05)

1. **源码树**:`Siflower/1806_SDK`(分支 `release2.0.0`,MIT,活跃)是完整源码树(OpenWrt 18.06 + Linux 4.14.90 + 官方 WiFi 驱动 sf_smac),但只含矽昌参考板(ac28/evb 等),**不含任何 GL.iNet 机型**。
2. **SFT1200 板级文件**唯一官方来源是 `gl-inet-builder/openwrt-imagebuilder-siflower-sf19a28-nand_3.8`(GL.iNet 官方,public),内含五件套:
   - `sf19a28_gl_sft1200_fullmask_def.config`(机型总配置)
   - `config-4.14_gl_sft1200`(内核配置,`CONFIG_MTD_NAND=y` 确认 NAND)
   - `profiles/sf19a28-gl-sft1200.mk`(机型 profile,显示名 GL.iNet SFT1200)
   - `base-files-SF19A28-GL-SFT1200/`(出厂默认文件)
   - DTS:`sf19a28_fullmask_gl_sft1200.dts`
   注意:GL 官方 SDK 仓库 `openwrt-sdk-siflower-1806` 只有 SF1200 定义,**没有** SFT1200;SFT1200 五件套只在 imagebuilder 仓库。
3. **gl-inet/gl-infra-builder 已被官方私有化**(404),公开 fork 仅含流水线配置、无机型定义,不可依赖。
4. 社区仓库 Big7ng/openwrt-sf-sft1200、ddb65536/openwrt_sft1200 等经核实实际使用矽昌参考板或 SF1200 配置,**产物与 SFT1200 NAND 硬件不匹配**,不可作为板级来源。
5. WiFi 校准数据(board-2.bin 类二进制)在官方 imagebuilder 仓库的 SFT1200 base-files 中**未确认存在**(抓取受限),需要编译首次跑通后核实,无则按 §7 fallback。
6. 18.06 SDK 官方推荐编译环境为 Ubuntu 14.04/16.04;GitHub Actions 现行 runner 为 Ubuntu 22.04/24.04,存在已知代际兼容问题(host gcc、openssl 1.x、ncurses 等),需自备兼容补丁(§6)。
7. **官方固件实测解剖**(2026-10-05,直链来自 `firmware-api.gl-inet.com/cloud-api/model/info?model=sft1200`,已下载 4.8.3 与 3.216 两版并 sha256 校验通过):两版镜像的 uImage 头均为 `MIPS OpenWrt Linux-4.14.90`——GL 4.x 只是应用层版本号,内核/驱动五年未变。镜像结构:`uImage(kernel, lzma)` @0x0 + `UBI(rootfs, squashfs zstd)` @0x400000。自编译 18.06 SDK 固件即官方最新固件同款内核与驱动底子。官方固件副本存于本项目 `firmware/` 目录。
8. **WiFi 校准数据不在任何官方仓库与固件镜像中**(已递归核查 imagebuilder 仓库全部 3149 项文件树,并解剖两版官方固件):校准数据为出厂写入每台机器 NAND 专用分区,预期由矽昌驱动经 DTS 分区定义直接从 NAND 读取,固件本身无需携带。另核实 `gl-inet/gl-image`(GL 新 GPL 合规源码发布仓库)仅覆盖 BE 系新旗舰,无 SFT1200。

## 3. 总体架构

三层拼装,全部官方来源:

```
┌─────────────────────────────────────────────┐
│ GitHub Actions workflow(自写)              │  流水线层
├─────────────────────────────────────────────┤
│ SFT1200 板级五件套 overlay                   │  板级层
│ 来源:gl-inet-builder/...-nand_3.8 imagebuilder│
├─────────────────────────────────────────────┤
│ Siflower/1806_SDK release2.0.0               │  源码层
│ (OpenWrt 18.06 + kernel 4.14.90 + WiFi 驱动) │
└─────────────────────────────────────────────┘
```

- **源码层**:workflow 运行时 `git clone https://github.com/Siflower/1806_SDK.git -b release2.0.0`,不 fork、不入库。
- **板级层**:五件套提取后作为文件提交进本仓库 `board/` 目录(一次性提取,git 历史可溯源到 GL 官方 commit hash),编译时 overlay 到源码树对应路径。
- **流水线层**:自写 GitHub Actions workflow,经典骨架(装依赖 → 拉源码 → 打补丁 → overlay → feeds → config → make download → make → 校验 → 上传)。

## 4. 仓库结构(新仓库,建议名 `sft1200-builder`)

```
sft1200-builder/
├── .github/workflows/
│   └── build.yml                  # 主构建 workflow
├── board/                          # SFT1200 板级五件套(从 GL imagebuilder 提取)
│   ├── sf19a28_gl_sft1200_fullmask_def.config
│   ├── config-4.14_gl_sft1200
│   ├── profiles/sf19a28-gl-sft1200.mk
│   ├── base-files-SF19A28-GL-SFT1200/
│   └── dts/sf19a28_fullmask_gl_sft1200.dts
├── patches/
│   └── host/                       # 18.06 SDK × 现代 Ubuntu runner 兼容补丁
├── scripts/
│   ├── apply-board.sh              # overlay 五件套到源码树
│   └── verify-image.sh             # 产物基础校验
├── feeds.conf                      # feeds 定义(钉版本,见 §8)
├── .config                         # 固件配置(基于 def.config 生成后固化)
└── README.md                       # 来源声明、刷机说明、许可证说明
```

## 5. Workflow 设计(build.yml)

- **触发**:`workflow_dispatch`(手动)+ `schedule`(可选,后期加)。
- **Runner**:`ubuntu-22.04`(若 18.06 兼容问题在 24.04 无解则固定 22.04,spec 不锁定,以实测为准)。
- **job 步骤**:
  1. apt 安装 18.06 依赖集(build-essential/gawk/git/libncurses-dev/unzip/xz-utils/file/wget 等,以趟坑实测清单为准);
  2. `git clone --depth 1 Siflower/1806_SDK -b release2.0.0`;
  3. 应用 `patches/host/*.patch`;
  4. 运行 `scripts/apply-board.sh` overlay 板级五件套;
  5. 安装 feeds(`feeds.conf` → `scripts/feeds update -a && install -a`);
  6. 装载 `.config`(`make defconfig` 校验);
  7. `make download -j8`(dl/ 目录用 `actions/cache` 缓存);
  8. `make -j$(nproc)`;
  9. `scripts/verify-image.sh`:校验产物存在、文件名含 `gl-sft1200` 字样、尺寸在合理区间(>8MB,<128MB);
  10. 上传 Artifact;打 tag 发 GitHub Release(保留最近 5 个)。
- **产物**:矽昌 SDK 打包流程输出 `*-factory.img`(U-Boot 刷入/救砖)与 `*-sysupgrade.*`(已刷 OpenWrt 后升级),命名以 SDK 实际输出为准。
- **超时与缓存**:job 超时 360 分钟(GitHub 上限);缓存 `dl/` 与 ccache,冷编译预计 2-3 小时(SDK 18.06 全量、mipsel 24kc)。

## 6. 兼容补丁策略(主要工程量所在)

18.06(2018)源码在 22.04/24.04(2026)runner 上的已知问题类别:

- host 编译器版本(老代码对 gcc 12+ 的告警/报错,`-Werror` 需关或代码修);
- host openssl:18.06 部分工具链要求 openssl 1.0/1.1,新系统仅 3.x → 静态编译 host 端 openssl 或 patch;
- ncurses/tinfo 链接变化(`menuconfig` 相关);
- Python 脚本语法(若有 py2 依赖,改写为 py3);
- 老下载源(源码内 `dl/` 镜像地址失效 → 换源或本地提供)。

原则:**每个坑一个独立 patch 文件**,进 `patches/host/`,commit message 注明问题现象与修复方式,保证可审阅可回退。补丁数量未知(预估 5-15 个),以首次实编输出为准——这是本设计唯一的"探索性"环节,时间盒 1-3 天;若遇阻(如 toolchain 无法在新系统编译),降级方案为在 workflow 中用容器锁定 `ubuntu:20.04` 镜像编译。

## 7. WiFi 校准数据策略

- **已核实**(§2.8):官方仓库与固件镜像均不含校准数据;它是出厂写入每台机器 NAND 专用分区的,矽昌驱动按标准做法经 DTS 分区定义直接从 NAND 读取。**因此固件本身预期无需携带校准文件**,前提是 overlay 的 DTS 中保留了该出厂分区(编译后需核对 `sf19a28_fullmask_gl_sft1200.dts` 的 mtd 分区表确认)。
- **验证路径**:首次真机刷入后实测 WiFi;若异常(无信号/速率极低),从原厂固件开 SSH,`cat /proc/mtd` 定位校准分区(名以实测为准),`dd` 导出对照——既用于排查,也可作为一次性备份存入 `board/` 私有目录。
- **边界**:不从 wekingchen 仓库取该文件(用户方案甲约束)。

## 8. UI 与插件机制(分阶段)

### 8.1 GL 官方功能 → LuCI 等价物映射(第二版插件清单参考框架)

| GL 官方功能 | LuCI 等价物 | 18.06 可行性 |
|---|---|---|
| 上网/无线设置 | LuCI 原生页面 + argon 主题 | ✅ |
| WireGuard VPN | luci-proto-wireguard + kmod-wireguard | ✅ |
| OpenVPN | luci-app-openvpn | ✅ |
| 中继 Repeater | travelmate | ✅ |
| AdGuard Home 去广告 | luci-app-adguardhome | ✅ |
| DDNS / UPnP | luci-app-ddns / luci-app-upnp | ✅ |
| 文件共享 | samba36 | ✅ |
| GoodCloud 云管理 / RTTY | 闭源私有 | ❌ 放弃 |
| iStore 商店 / quickstart 仪表盘 | 官方仅支持 OpenWrt 21.02+,架构 x86/arm64 为主 | ❌ 18.06 无支持 |
| Open-Box(liandu2024,sing-box 面板,1719★) | 仅发布 x64/arm64 预编译包(完整包 71-76MB,内置 Node 运行时);SFT1200 为 mipsel 32 位、rootfs ~20MB、RAM 128MB | ❌ 三重不满足;代理功能改用 18.06 生态 luci-app-passwall / ssr-plus + 轻量内核(Xray/SS-libev);sing-box mipsle 自编列为第二版可选项(内存吃紧,不承诺) |
| 统一引导首页(iStoreOS 式) | 无现成方案;可选**自制 lua 引导页**(第二版评估项) | ⚠️ 可选自制 |

### 8.2 插件机制

- **第一版(用户 2026-10-05 定稿)**:最小运行版——官方驱动 + LuCI + 基础无线(AP 模式广播)+ DHCP(dnsmasq)+ **argon 主题**(用户指定,开源第三方,选 18.06 兼容分支/版本,直接从其官方仓库引入,不经第三方 feed)。目标:流水线跑通 + 产物可刷可开机 + WiFi/DHCP 可用。其余一律不加。
- **第二版(用户清单后定)**:用户 2026-10-05 已勾选优先级——①VPN(WireGuard+OpenVPN)②中继/访客网络(travelmate+多 SSID)③去广告+DDNS+UPnP(AdGuardHome/ddns/upnp)④文件共享(samba36)+自制引导页评估;另核实 Open-Box(sing-box)不可移植(§8.1),代理类需求由 luci-app-passwall / ssr-plus + 轻量内核承接。落地流程:逐个核实 18.06 可编译性 → 加进 `feeds.conf`(钉 commit)+ `.config`(`CONFIG_PACKAGE_xxx=y`)→ 重编验证。
- **硬约束**(已向用户说明):机器架构 `mips_siflower` 无在线 opkg 官方源,一切插件必须编译期打包;依赖 nftables 的新一代插件(OpenClash、passwall2 等)在 18.06 无支持;Go 类插件需引入新 Go toolchain feed,列为第二版评估项。
- feeds 源原则:全部使用 openwrt 官方 github 镜像(coolsnowwolf 等第三方 feed 是否引入由第二版插件清单决定,默认不引入)。

## 9. 刷机与验证

- 产物刷法:`*-factory.img` 经 U-Boot 恢复模式刷入(救砖同路径);`*-sysupgrade.*` 用于 OpenWrt 运行中升级。刷机由用户执行,本仓库 README 提供步骤与风险说明。
- 自动化校验仅覆盖:编译成功、产物命名、尺寸区间、(可选)`file`/`binwalk` 结构检查。
- **真机验证以用户为准**:能否开机、WiFi 是否正常、LuCI 是否可访问。首次刷机前必须备份原厂固件(dd 全盘)。

## 10. 风险与边界

| 风险 | 等级 | 对策 |
|---|---|---|
| 18.06 × 新系统编译坑超出预期 | 中 | 时间盒 1-3 天;降级用 ubuntu:20.04 容器 |
| WiFi 校准依赖 DTS 分区保留正确 | 低-中 | 编译后核对 DTS 分区表;真机实测兜底(§7) |
| 矽昌 SDK 上游变更破坏编译 | 低 | SDK clone 固定 release2.0.0 + commit hash |
| 刷机变砖 | 低(有 U-Boot 救援 + factory.img) | README 风险说明 + 备份原厂固件 |
| 4.14 内核无安全补丁 | 已接受 | 用户确认;README 提示 WAN 侧最小暴露 |

**不做的事(YAGNI)**:不做 update-checker 自动跟随上游(第一版);不做多机型支持;不做本地编译脚本优化(Actions 是唯一目标);不做 passwall2/OpenClash(18.06 无支持)。

## 11. 验收标准

1. 本地/Actions 推送后手动触发,流水线端到端成功,Release 产出 factory.img + sysupgrade 包;
2. 产物文件名可识别对应 SFT1200 机型(按 overlay 后 profile 命名规则,含 `gl-sft1200` 或 `SF19A28-GL-SFT1200` 字样),尺寸合理;
3. 用户真机刷入后:可开机、LuCI 可访问、WiFi 可用(有校准数据后);
4. README 完整:来源声明(三个官方仓库 + commit hash)、刷机步骤、许可证说明(矽昌 MIT / GL 板级文件按其仓库许可 / 本仓库文件归属)。

## 12. 后续流程

本 spec 获批后,启用 `superpowers:writing-plans` 生成分步实施计划(预计阶段:仓库骨架 → 板级提取与 overlay 脚本 → workflow v1 → 首次编译趟坑 → 校准数据核实 → 文档)。
