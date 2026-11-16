# Celechron Liquid Glass Edition 第一阶段审查与开发计划

核查日期为 2026 年 11 月 16 日（北京时间）。报告中的「已验证」指本机命令、GitHub 远端、固定提交源码或发布归档给出了证据。「方案」是供后续实现的技术选择。「待验证」需要构建产物、设备或真实业务场景才能确认。

## 1. 环境检查报告

| 项目 | 已验证结果 |
| --- | --- |
| 工作目录 | `D:\Celechron_Liquid_Glass_Edition` 开始时为空，`git status` 确认尚未初始化为 Git 仓库。本报告保存在此目录，源码审查及命令验证在独立临时克隆中完成。临时克隆的本地 `main` 初始工作树干净，远端指向官方。 |
| Git / Flutter | Git 2.55.0.windows.5。Flutter 实际运行版本为 3.47.4 stable，框架 `9584c6713b`，引擎 `06a2e2a110`，位置为 `D:\flutter`。 |
| Dart / Java | Dart 3.13.3 stable。命令行和 Flutter Android 工具链均使用 Temurin JDK 17.0.20.1，后者由 Flutter 配置显式指定。Android Studio 自带的 JBR 25.0.2 与此次 Flutter 选用的构建 JDK 是两个安装。 |
| Android SDK | Doctor 的 Android toolchain 通过，许可证均已接受。SDK 位于 `C:\Users\administrator1\AppData\Local\Android\sdk`。已安装 API 34、35、36，Build Tools 35.0.0、36.0.0，NDK 28.2.13676358，Command-line Tools 23.0，ADB 37.0.1。 |
| Android 设备 | `flutter devices` 仅列出 Windows 和 Edge。已有 `Medium_Phone` AVD，配置为 Android 37.1、x86_64、host GPU，镜像文件存在。模拟器的 `-accel-check` 确认 WHPX 可用。此轮设备检测时没有运行中的 Android 设备。 |
| Gradle | 官方项目锁定 Wrapper 8.13、AGP 8.13.2、Kotlin 2.2.0，Java/Kotlin 编译目标 11。上游追踪 Wrapper 配置文件，CI 生成 Wrapper 脚本和 JAR。临时克隆的 `gradlew.bat --version` 实测为 Gradle 8.13 / JDK 17.0.20.1。本机缓存中另有可运行的 Gradle 9.3.1。 |
| 网络 | Flutter Doctor 对 GitHub 连通性报错。Git 和 Pub 通过进程级代理成功访问远端。Doctor 另报 Chrome 可执行文件定位问题，Android 工具链检测独立通过。 |
| 依赖解析 | 固定提交的临时克隆中，Flutter 3.47.4 上的 `flutter pub get` 成功解析 130 项依赖。上游忽略 `pubspec.lock`，其中 Workmanager Git 依赖跟随自身的 `main`，本次解析到 `d7e6ba5ef3796fafe54d9739e481f01058751b4d`。 |
| 原版分析与测试 | `flutter analyze --no-pub --no-fatal-infos` 退出 0，有 21 条既有 info，均为 `calendar_to_system.dart` 中的 `use_build_context_synchronously`。首次测试受进程代理影响，本地测试 WebSocket 连接失败。排除回环流量代理后重跑，原版 119 项测试全部通过。 |
| Android Debug APK | 执行了 `flutter build apk --debug --no-pub`。Wrapper 启动后，Gradle 线程长时间等待 HTTP 下载，本轮停止了该次尝试，未生成 APK。另行探测的 Google Maven、Gradle Plugin Portal 与 Maven Central 三个 POM 均可通过代理请求，卡住的具体构件待用 Gradle 详细日志确认。 |

本机 Flutter 的 Gradle 插件定义 `compileSdk=36`、`targetSdk=36` 和 `ndkVersion=28.2.13676358`。固定提交的 Android 配置引用这些 Flutter 值，显式 `minSdk=28`。这组值与已安装的 SDK、NDK 对应。AGP 官方兼容表将 JDK 17 和 Gradle 8.13 列为该版本线的最低及默认组合。 [上游 Android 构建配置](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/android/app/build.gradle) · [上游 Gradle Wrapper 配置](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/android/gradle/wrapper/gradle-wrapper.properties) · [AGP 8.13 兼容表](https://developer.android.com/build/releases/agp-8-13-0-release-notes)

Flutter 在临时克隆中生成了依赖锁、平台插件注册文件和 Wrapper。跟踪文件的差异限于桌面平台生成的注册文件，`pubspec.yaml` 与业务源码保持官方基线。正式工作目录只增加了本文。

## 2. 上游代码基线

- 官方默认分支为 `main`。本次用 Git 直接查询到 HEAD 为 `724e54a3d8feb190a90544963cd53e8ef01c0ff9`，随后核对了 GitHub 提交元数据、临时克隆 HEAD 及 Git tree `c0eb09d78537d2741d54c3849679853c632f09ee`。提交时间是 2026-09-20 19:52:17（北京时间），合入 PR #184，修复未来学期校历未发布时误触发降级提示。应用版本为 `1.3.1+1`。 [官方提交](https://github.com/Celechron/Celechron/commit/724e54a3d8feb190a90544963cd53e8ef01c0ff9) · [上游 pubspec](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/pubspec.yaml)
- 目标地址初始匿名查询返回 404。已登录的 GitHub 派生页面显示个人账号 `rhys-mount` 可以使用仓库名 `Celechron`，据此创建了只复制 `main` 的 Fork。创建后，GitHub API 确认 `fork=true`、父仓库为 `Celechron/Celechron`，且 Git 远端确认目标 `main` 与上游完整 SHA 一致。目标远端尚无 `liquid-glass` 分支。 [目标 Fork](https://github.com/rhys-mount/Celechron)
- 旧版参考是公开的独立仓库，远端 `main` 为 `63187f3c5e26a882b45419d10dfaefda454aff6c`。本轮仅核对其仓库元数据与分支指针。后续可参考其界面呈现、交互和已知问题，所有实现从官方源码开始。 [旧版参考](https://github.com/rhys-mount/Celechron-1.3.1-liquid-glass)

## 3. 项目架构和五个主页面

**启动与导航。** `lib/main.dart` 初始化 Hive、`DatabaseHelper` 及带 tag 的 GetX 状态，启动 `GetCupertinoApp`，根据 `Option.brightnessMode` 提供应用亮暗主题。它还负责 24 小时制、通知、前后台刷新协调、校园卡组件与 `celechron://ecardpaypage` 深链。 `HomePage` 管理唯一 `PageController`，将点按和滑动选中态汇总到 `onPageChanged`。五页实例稳定并保活，屏蔽旧有页面内 Hero 飞行动画，支持鼠标拖动切页。子页面多处使用根 Navigator。 [启动入口](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/lib/main.dart) · [导航壳](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/lib/page/home_page.dart)

| 顺序与页面 | 原版源码与职责 | 界面改造和验收重点 |
| --- | --- | --- |
| 1. 接下来 | `flow/flow_view.dart` 与 `FlowController`。显示时间规划、当前与后续事件，包含进度、规划过期提示和重新规划。 | 先迁移标题及操作按钮。保留时间线排序、颜色语义、空态、进度与重规划反馈。计时或滚动时避免整块玻璃随列表重绘。 |
| 2. 日程 | `calendar/calendar_view.dart`、`schedule_view.dart` 与 `CalendarController`。月／周日历、日历／日程列表模式、今天定位与当天事件。任务和规划状态由已存在的控制器共享。 | 日历格、事件及标记用实底。复测横向翻月与外层切页竞争、当前日期和选中日期、模式切换、事件详情和编辑。 |
| 3. 任务 | `task/task_view.dart` 与 `TaskController`。分组展示任务，支持新增、编辑、完成、暂停／继续和批量动作，并与 `FlowController` 联动。 | 高密度列表用实底，先换顶部入口。复测草稿、键盘、日期选择、完成／过期和重复任务、取消返回值以及修改后重规划。 |
| 4. 学业 | `scholar/scholar_view.dart` 与 `ScholarController`。课程、课表、考试、作业、成绩／GPA、实践记点。页面有固定头、横向卡片列表及下拉刷新，提供失败与降级反馈。 | 保留原有信息顺序和导航入口。覆盖未登录、缓存恢复、部分失败、手动刷新与启动刷新并发、成绩隐藏及横向手势。标题与刷新反馈先复用现有结构。 |
| 5. 设置 | `option/option_view.dart` 与 `OptionController`。登录登出、教务选项、后台刷新和通知、规划参数、系统日历／iCal、暗色模式、付款码和诊断。 | 保持原分组和入口。优先实底分组与现有控制器回调，验证亮暗三态、权限拒绝和开关保存，保留校园卡深链与诊断导出。 |

各页面与配套控制器以锁定提交为准。 [五页源码目录](https://github.com/Celechron/Celechron/tree/724e54a3d8feb190a90544963cd53e8ef01c0ff9/lib/page)

**业务与数据边界。** `lib/algorithm` 负责规划，`lib/model` 持有学业、课程、任务和时段等模型，`lib/database` 定义 Hive box、Adapter typeId、序列化与 Secure Storage 接口，`lib/http` 和 `lib/services` 处理抓取、认证、配置、诊断和刷新协调，`lib/worker` 处理后台刷新、更新检查和校园卡组件。Android 端还有 Kotlin `MainActivity`、校园卡 Glance 组件和 MethodChannel。界面层可读取现有可观察状态并调用原回调。数据 key、字段编号、认证会话、任务状态转换、路由名、Intent 和 Channel 名都应纳入回归验收。 [上游 lib 目录](https://github.com/Celechron/Celechron/tree/724e54a3d8feb190a90544963cd53e8ef01c0ff9/lib) · [Android 主 Activity](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/android/app/src/main/kotlin/xyz/nosig/celechron/MainActivity.kt)

## 4. 技术选型及依据

### 依赖与 API

已核实 pub.dev 最新稳定版为 **`liquid_glass_widgets 1.17.4`**，发布于 2026-11-16 08:59:49（北京时间）。发布归档已按 registry SHA-256 校验，摘要为 `81e3062548c9efd60bda90e9c4ed12c30d66c870fd059f5e298826f0866688d0`。包为 MIT，运行时依赖只有 Flutter SDK，要求 Flutter ≥3.41.0、Dart ≥3.5.0 且 <4.0.0。本机 Flutter 上的 `flutter pub add liquid_glass_widgets:1.17.4 --dry-run` 成功，仅此一项会变更。上游 APK CI 固定 Flutter **3.38.1**，低于包的下限。建议单独提交 `liquid-glass` 的 CI 工具链对齐，在确定基线能构建后固定 Flutter 3.47.4 和应用依赖锁。 [包版本](https://pub.dev/packages/liquid_glass_widgets/versions) · [1.17.4 发布说明](https://pub.dev/packages/liquid_glass_widgets/changelog#1174) · [上游 APK CI](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/.github/workflows/build_apk.yml)

| 从发布归档核实的 API | 项目拟用方式 |
| --- | --- |
| `LiquidGlassWidgets.initialize({warmUpMode, enablePerformanceMonitor})` | 完成 Flutter binding 后，在主 isolate 的 `runApp` 前预载。按官方启动路径保留业务初始化顺序，在技术验证中测启动开销与失败回退。 |
| `LiquidGlassWidgets.wrap(child: ..., theme: ..., adaptiveQuality: ...)` | 在现有 Cupertino 应用外层或其 builder 处试验主题作用域，验证实际解析亮度与应用的三种模式同步。库的性能自适应为实验功能，先用明确的质量策略，实测后再决定启用范围。 |
| `GlassTabBar.bottom(tabs: ..., selectedIndex: ..., onTabSelected: ...)` 与 `GlassTab` | 复用五个标签及其顺序，用 `onTabSelected` 驱动原 `PageController`，用 `onPageChanged` 统一回写选中态。首轮验证窄屏、大字体、滑动同步与原页面保活。 |
| `GlassScaffold`、`GlassAppBar`、`GlassStatusBarStyle.none` | 库可管理栏位、延伸布局及边缘淡化。先在单页验证其布局职责，首轮主壳沿用原 `PageView` 布局。使用库 scaffold 时明确关闭其系统栏样式接管，除非该页已切换到唯一的系统栏样式控制点。 |
| `GlassThemeData.ios26()`、`GlassSurfaceStyle.solid` | 发布版默认预设为 `ios27`。本方案选择显式固定 `ios26` 作为首轮视觉起点。内容层使用实底与语义色，玻璃优先用于悬浮导航、少量工具按钮及必要的浮层。 |

采用「库负责材质与局部控件、Celechron 负责导航与状态」的边界。保留 `GetCupertinoApp`、根 Navigator 和现有业务回调。从底栏试验开始，确认滚动内容、触摸区域和系统边栏后再改应用栏。日期格、任务清单、成绩表及设置行继续以高可读性的内容层呈现。库封装比自写 Shader 或全面迁移 UI 框架更便于保持实现范围及单独回滚。初版用原 `CupertinoTabBar` 作为可切回的路径，和新底栏共用标签与状态源。 [库 API 与示例](https://pub.dev/packages/liquid_glass_widgets/versions/1.17.4) · [Apple HIG 材质与层级](https://developer.apple.com/design/human-interface-guidelines/materials.md)

### Android Edge-to-Edge

**已验证源码。** 上游 `_initStatusBar()` 已调用 `SystemUiMode.edgeToEdge`，通过 `SystemUiOverlayStyle` 设置状态栏图标亮度并请求透明导航栏。Manifest 启用硬件加速与 `adjustResize`。现有主页手动把底栏高度传入内容的 `MediaQuery.padding.bottom`，将 IME inset 转为内容 Padding，各页部分使用 `SafeArea`。此次使用的 Flutter 默认 target 为 36。Android 15 设备对 target 35 及以上启用 Edge-to-Edge，Android 16 设备在 target 36 下关闭平台退出机制。三键导航时由系统处理的对比衬底和图标颜色，需要与手势导航分别验证。 [Flutter Edge-to-Edge](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge) · [Android Edge-to-Edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge) · [Android 16 行为变化](https://developer.android.com/about/versions/16/behavior-changes-16)

**方案与验收。** 在根壳统一计算底部系统安全区、悬浮栏的实际占位和 IME 避让，用同一份计算结果向内容提供 inset。玻璃背景可以延伸到系统栏，文字、最后一条列表项和按钮须可阅读、可点击。底部 inset 只在约定的布局层消费一次，保持键盘打开时编辑焦点与提交动作可达。以实际栏背景决定系统栏图标对比度，测试前后台切换、横屏／刘海、导航手势／三键、输入法、深色模式和返回手势。库 scaffold 与原 `SafeArea` 的组合需要实测。

### Shader 条件与降级

**已验证编译。** 用本机 Flutter 3.47.4 的 `impellerc`，按 Flutter Android 构建同组目标（SkSL、GLES、GLES3、Vulkan）离线编译 1.17.4 中声明的 5 个 fragment shader。五项均退出 0 并生成输出。此轮通过的是编译器检查，Android 应用中的资产加载、设备后端、图像滤镜、驱动行为与帧率均需上机验证。 [Flutter Fragment Shader](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)

**方案。** `GlassQuality.premium` 的深度折射路径应以 `ImageFilter.isShaderFilterSupported` 及设备实测为依据。Flutter 文档描述 Android API 29+ 默认启用 Impeller，实际渲染后端受 OS、GPU 和驱动影响。`standard` 是轻量片元 Shader，兼容范围由库和运行环境决定。`minimal` 使用常规背景模糊与描边，仍有模糊成本；需要更稳定的方案时使用有足够对比度的不透明表面或原版栏。库内部部分路径会按能力及资源初始化结果回退，应用还需要可独立关闭玻璃的路径。首轮用 `standard` 验证主要机型，`premium` 仅比较主底栏和少量静态控件，暂不指定为全机型默认。 [Flutter Impeller](https://docs.flutter.dev/perf/impeller) · [ImageFilter.shader](https://api.flutter.dev/flutter/dart-ui/ImageFilter/ImageFilter.shader.html) · [库的渲染等级](https://pub.dev/packages/liquid_glass_widgets/versions/1.17.4)

设备测试使用同一份样例数据、相同设备和刷新率，对比原版和新底栏的冷启动、连续切页、长任务列表与学业卡片滚动。使用 Profile 模式采集 Flutter DevTools 帧时间，并用设备日志记录真实后端。另跑关闭 Impeller 和关闭玻璃两条路径，验证首页与导航可用性。

## 5. 文件结构设计

在现有 `lib/design/` 下集中管理材质与回退。下面是建议的增量，文件按对应功能提交逐步加入。

```text
lib/
  main.dart                              # 保留启动流程，接入主题与预载
  design/
    liquid_glass/
      glass_theme.dart                   # 亮暗材质、前景色、形状与间距
      glass_render_policy.dart           # 质量选择、系统可访问性与安全回退
      glass_tab_bar.dart                 # 五标签的玻璃／原版栏适配
      glass_page_chrome.dart             # 真正复用时提取标题栏与操作按钮
  page/
    home_page.dart                       # 保活、选中态、主页 inset 和系统栏协调
    {flow,calendar,task,scholar,option}/  # 在原 view 中渐进替换显示部件
test/
  liquid_glass/
    home_navigation_test.dart           # 点按、滑动、保活与回退
    home_insets_test.dart               # 系统安全区和 IME 避让
.github/workflows/
  …                                      # 为 liquid-glass 单独配置验证入口
```

视图继续调用所在页面的控制器，通用玻璃部件只接受渲染所需的值、标签和回调。状态、持久化、校园集成与平台组件仍沿用现有位置。优先保留当前 `lib/design` 的基础卡片组件，按具体页面的复用情况添加公共标题栏，系统栏或 Android 主题只有在设备验证发现问题时才调整。

## 6. 主要风险

| 优先级 | 风险及依据 | 应对与验证 |
| --- | --- | --- |
| 高 | CI 的 Flutter 3.38.1 与新依赖要求冲突。当前上游代码检查追踪 stable，测试步骤被注释，APK workflow 绑定原版签名证书。 | 首先对照固定提交获取分析、测试和 APK 基线。Fork 验证使用自己的 Debug 签名环境，明确配置 `liquid-glass` 的 PR 检查。将工具链、依赖及 UI 提交拆开。 |
| 高 | 模糊、折射和重绘带来光栅耗时、显存压力、GPU 或驱动兼容问题。 | 控制高质量玻璃数量及裁剪范围，避免全屏或逐单元采样。真机 profile 对照原版、Standard 和 Premium，记录 UI／raster P95、掉帧率与冷启动；验证无 Shader 和原版回退。 |
| 高 | 新底栏和原主页都可能处理 SafeArea／IME，造成空白、遮挡和手势冲突。 | 单点消费 inset，测试阅读区与触控区，覆盖系统导航模式、横竖屏、弹窗、普通返回及 Android 16 预测返回。 |
| 高 | 重新建立页面或 Navigator 会导致 GetX 实例、滚动位置、计时器、学业刷新或深链行为变化。 | 保持现有 PageView 和页实例的生命周期。用离线基线数据验证切页保活和路由返回，在登录态验证单次刷新及校园卡打开路径。 |
| 高 | 上游使用 `xyz.nosig.celechron`，发布签名身份存在明确约束。试验 APK 和正式版可能因同包名、不同签名而无法共存或覆盖安装。 | 用专用设备或 AVD 做 Debug 检查，禁止为了覆盖安装清除用户数据。分发阶段另行确定包名、签名和升级策略，验证 Hive 读取、旧数据兼容、通知和深链。 |
| 中 | 五标签中文、窄屏、放大字体、弱对比背景及亮暗主题可能造成截断或难以区分。 | 标签和语义齐全，检查 TalkBack、放大字体、高对比、减少动态效果、明暗三态及禁用控件。内容密集区域使用实底。 |
| 中 | 未锁定的 pub 或 Git 依赖、Wrapper 镜像和移动端工具链分歧可使构建随时间漂移。 | 记录 Flutter / JDK / Gradle / AGP / NDK 与解析锁，给 `liquid-glass` 提交可复现的锁文件。独立复审 Workmanager 的解析 SHA、依赖升级及 Wrapper 来源。 |
| 中 | 上游以 GPL-3.0 发布、玻璃库为 MIT，Fork CI 的签名和发布流程也有独立配置。 | 保留许可证和归属，分发前检查源码、第三方声明与对应构建方式。签名身份与发布审批单独处理。 [上游许可证](https://github.com/Celechron/Celechron/blob/724e54a3d8feb190a90544963cd53e8ef01c0ff9/LICENSE) |

## 7. 后续开发路线与分支策略

**分支方案。** 正式工作区从 `origin = rhys-mount/Celechron` 克隆，添加只用于读取和同步的 `upstream = Celechron/Celechron`。`main` 跟踪官方 `main`，新同步用快进方式并先校验共同历史。首次 `liquid-glass` 以本文完整 SHA 建立。若开始开发前上游已有新提交，先核对变动并更新基线记录。`liquid-glass` 承载 Edition 代码与 CI，每个小工作分支经单独 PR 合入。后续上游同步采用独立合并 PR，记录来源 SHA、冲突和回归结果。合并后的回滚用 revert 保留审查记录。

| 阶段 | 独立提交与交付 | 进入下一阶段的证据 |
| --- | --- | --- |
| 2A. 复现原版 | 建立工作区、配置两个远端和开发分支。用 Gradle `--info` 与受控网络超时定位下载等待，生成 Debug APK 与原版截图。记录原版固定 SDK、依赖和分析／测试现状，必要的构建兼容修复独立提交。 | 官方基线可定位。编译和测试结果可复跑，现有缺陷有记录。API 35/36 至少有一个可运行设备。 |
| 2B. 技术验证 | 独立提交固定工具链／依赖、玻璃主题预载、能力探针和回退。先用单处表面对照渲染，再引入底栏。 | 实测 Shader 资产加载、UI／raster 时间、原版回退和亮暗对比。无 Shader 环境也能启动和交互。 |
| 2C. 导航壳 | 独立提交底栏、主页 inset 和系统栏处理；保留原标签顺序、一次性页面构造、页面滑动与根 Navigator。 | 五页点按与滑动一致，重访保留状态。短屏、键盘、横屏、刘海和两种系统导航模式下无遮挡。 |
| 2D. 五页迁移 | 建议顺序为「接下来 → 任务 → 日程 → 学业 → 设置」。先替换导航和操作层，每页一个 PR；需要改造的详情页或弹层另开 PR。 | 输入内容、持久化结果、通知、认证、日历权限、深链和刷新行为与原版逐项对照，逐页可回滚。 |
| 2E. Android 验收与发布准备 | 首轮覆盖 API 28 或其他可稳定复现的低版本／无 Shader 环境、API 35 与 36、至少一台物理 Android。再覆盖高低 GPU、主题、长列表、高刷新和可访问性，构建候选 APK。 | 保留基线与改造版 Profile 记录。60 Hz 每帧时间预算约 16.7 ms，120 Hz 约 8.3 ms，按设备刷新率记录 UI 与 raster 分布。正式签名、安装升级及数据兼容需要单独验证。 |

建议每个 PR 附相关前后截图、基线 SHA、复现步骤、自动化结果和涉及的回退方式。优先使用合成数据验证布局与键盘，再用诊断日志验证校园网络下的实际业务路径。
