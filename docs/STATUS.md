# Celechron Liquid Glass Edition 项目状态

更新日期为 2026 年 11 月 16 日（北京时间）。2A 原版 Android 基线已通过，进入 Edition 工程基础与底栏 MVP。

## 文档依据

- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) 第 V1.0 版是已确认的产品需求基线。
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) 保留第一阶段的技术审查证据、风险和实施建议。产品范围与执行优先级以需求基线为准。
- [AGENTS.md](../AGENTS.md) 约定任务前阅读项目文档、任务后更新本页。[DECISIONS.md](DECISIONS.md) 记录实施中采用的技术决策。

## 已完成与已核实

| 事项 | 状态与证据 |
| --- | --- |
| GitHub Fork | 本轮重新查询官方与 [目标 Fork](https://github.com/rhys-mount/Celechron) 的远端引用。两者的默认分支均为 `main`，均指向 `724e54a3d8feb190a90544963cd53e8ef01c0ff9`。目标 Fork 尚无 `liquid-glass` 分支。 [官方提交](https://github.com/Celechron/Celechron/commit/724e54a3d8feb190a90544963cd53e8ef01c0ff9) |
| 本地工作区 | 已从核对过的官方快照建立 Git 仓库，`origin` 指向目标 Fork，`upstream` 指向官方并禁用本地推送。初始检出为浅克隆，`main` 与两条远端跟踪引用均为官方基线。本地已建立 `liquid-glass`，开发改动位于独立 feature 分支。 |
| Android 原版基线 | `feat/android-toolchain` 的 `ff9c6f2` 只调整 Android 构建配置。成功生成 Debug APK，API 36 独立模拟器验证五个标签的点按、页面内容与横向滑动。原版 APK、六张截图及语义树在本地 `.local/baseline/`。另在 API 37.1 的 16 KB 页大小模拟器安装成功，首次启动到通知授权界面。 |
| 第一阶段工程检查 | 原版五个主页面、GetX／Hive 架构、导航生命周期和 Android Edge-to-Edge 已做源码审查。Flutter 3.47.4、Dart 3.13.3、Temurin JDK 17、Android SDK 和项目 Gradle 8.13 Wrapper 已检查。已有 `Medium_Phone` AVD，第一阶段尚未运行应用。 [技术审查记录](IMPLEMENTATION_PLAN.md) |
| 原版依赖、分析与测试 | 第一阶段 `flutter pub get` 成功，`flutter analyze --no-pub --no-fatal-infos` 退出 0，含 21 条既有 info。排除回环代理干扰后，119 项原版测试全部通过。本轮复核了留存日志。 |
| Liquid Glass 技术检查 | 首选依赖 `liquid_glass_widgets 1.17.4` 已完成发布归档校验、依赖解析预演和 5 个 Shader 的 Android 目标离线编译。实际 APK 集成、GPU 渲染、画质降级和性能仍待设备验证。 |
| 文档整理 | 将 `IMPLEMENTATION_PLAN.md.md` 改为 `IMPLEMENTATION_PLAN.md`，SHA-256 校验确认内容一致。完成文档对照并初始化本页。 |

## 未完成事项

- Edition 的远端分支、PR 和 GitHub Actions 运行尚待验证。原版 App 的登录态校园业务与 Android 真机仍待回归。
- Liquid Glass 底栏 MVP 及其回退尚未实现。顶部导航、五页与二级页面改造、求是蓝主题、总开关持久化、过期横幅移除、关于页署名、图标、启动页、平板适配和 Release 流程均待实施。
- iOS 26／27 预设、设备默认画质、深色强调色的精确值、`GlassScaffold` 使用范围、平板断点及 Sidebar／Split View 实现仍待验证或定案。`#5B9BEE` 是深色候选值。

## 文档核对结果

| 类型 | 发现及后续读法 |
| --- | --- |
| 路径引用 | `AGENTS.md` 指定的实施计划原有双后缀，已修正。产品上下文多次沿用第一阶段报告的旧文件名 `Celechron-第一阶段审查与开发计划.md`，对应现有 [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)。 |
| 重复 | `AGENTS.md` 的核心规则与产品上下文第十四节重复，作为入口摘要时一致。上下文第十二、十三、十五节与技术计划重复记录工程进度和路线，也有同一报告文件名多次出现。后续实际进展更新本页，第一阶段数据按原核查时点阅读。 |
| 冲突 | 技术计划第 6 节把包名、签名和升级策略写为分发阶段另行确定。产品上下文第十节已确认保留 `Celechron` 和 `xyz.nosig.celechron`，建立固定、独立的 Release 签名。与官方版共存及无损覆盖旧版均无硬性要求。待办是落实签名和验证实际安装方式。 |
| 原型与定案 | 技术计划第 4 节的 `ios26` 和 `standard` 用于首轮试验。产品上下文第十一节要求比较 iOS 26／27，并实测画质。正式预设和默认画质待定。按第六节实现默认开启且持久化的总开关，关闭后回到 Cupertino，底层可以自动降级，用户界面无手动画质档位。 |
| 范围遗漏 | 技术计划侧重首轮工程，验收时还需按产品上下文覆盖浅色求是蓝 `#003F88`、顶部导航、图标与启动页、平板横屏和关于页。技术计划对「接下来」的过期提示描述的是原版现状。后续按需求仅移除提示横幅，保留重新规划入口、过期判断和更新机制。 |
| 阶段顺序与过时叙述 | 技术计划把开发分支配置并入 2A，产品上下文第十三节把原版构建与运行放在前面。按后者安排。技术计划中「正式工作目录只增加了本文」是第一阶段快照，上下文中「补全项目需求文档」已落实为现有 V1.0 基线。 |

## 下一阶段任务

1. **验证 Edition 工程基础。** 检查原版依赖锁与 Edition CI 配置，并提交独立变更。
2. **验证底部 Tab Bar MVP。** 保持「接下来 → 日程 → 任务 → 学业 → 设置」、原有 `PageView`、页面保活和根 Navigator。对照 iOS 26／27 候选，验证应用主题三态、系统栏、键盘、列表末项、手势、着色器降级和总开关回退。设备结果确认后，再按页推进具体视觉改造。
