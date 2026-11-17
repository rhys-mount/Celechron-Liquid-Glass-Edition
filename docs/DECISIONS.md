# Celechron Liquid Glass Edition 技术决策

产品决策以 [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) 为准。以下记录实施中已采用的技术做法及其适用范围。

## 2026-11-16 · Android 原版基线验证使用独立模拟器

复用本机已安装的 Android 37.1 x86_64 系统镜像，创建 `Celechron_Isolated_API_37_1`。应用数据位于项目本地专用目录，测试通过固定的 `emulator-5564` 连接。这样可以用原版包名验证安装、启动和后续更新路径，并隔离日常设备与既有 AVD 的数据。手机兼容性与正式签名仍按需求基线验收。

API 36 验收使用同样隔离的 `Celechron_Isolated_API_36`（`emulator-5566`）。系统镜像来自 Google SDK 仓库，按其发布校验值核验。

## 2026-11-16 · 对齐 Android 构建工具链

采用 Flutter 3.47.4、JDK 17、Gradle 8.14.5 与 Kotlin／Compose 插件 2.2.20。原版构建日志确认 Gradle 8.13 未达到 Flutter 校验下限。保留 AGP 8.13.2、应用身份与最低 API 28。Gradle Wrapper 使用官方发行地址和 SHA-256，构建分支与官方 `main` 分开。

本机的依赖下载通过进程级配置让 Maven Central、Google Maven 和 Flutter Maven 存储直连。由于官方 Gradle 下载重定向在本机被拒绝，首次使用镜像预取，按官网 SHA-256 核对后放入同 URL 对应的 Wrapper 缓存。项目配置继续指向官方地址。

## 2026-11-16 · 底栏试验与回退

底栏接入保留现有 `HomePage`、`PageController`、五页实例和根导航。玻璃栏和 Cupertino 栏共用五个标签和回调。外观开关使用已有 Hive 设置盒内的一条新布尔键，缺省开启，关闭时在原位置切回 Cupertino。

MVP 用 iOS 26 材质作为试验起点，用 `--dart-define=CELECHRON_GLASS_IOS27=true` 构造 iOS 27 对照。底栏试验采用 Standard，运行时 Shader 滤镜不可用则尝试 Minimal，预载异常时使用 Cupertino。正式材质、画质与深色强调色继续按设备验收决定。

## 2026-11-16 · Android 底栏简化选中态遮罩

API 37.1 模拟器的同序列 Profile 采样显示，关闭库的双层遮罩后 Raster P95 从 60.59 ms 降到 20.25 ms。Android 使用库的简化遮罩，继续使用悬浮玻璃表面、滑动选中态和原有触摸反馈。用户开关与内部渲染策略独立。实机长列表与高刷新率场景仍待验收。

对简化遮罩增加底栏矩形裁剪后，同一序列 Raster P95 升至 27.51 ms。撤回裁剪试验，以 20.25 ms 的方案进入页面迁移，底栏帧时间继续列入发布验收。

随后 API 36 与 API 37.1 截图复核发现，库的简化模式会将选中内容绘制在错误的位置。简化遮罩的耗时保留为试验数据，界面继续比较能保持选中态的渲染方式。

Android 恢复完整遮罩，选中胶囊使用 Minimal，底栏背景保留能力检测。Profile 截图确认求是蓝随选中项从首个标签移到中间标签，且图标和文字保持对齐。Raster P95 结果为 42.81 ms，发布验收继续对照不同设备的帧时间。

## 2026-11-16 · 顶部操作按钮共用外观策略

「接下来」保留 Cupertino 大标题及其滚动收缩。独立玻璃操作按钮共用外观总开关和 Shader 能力降级，使用同一回调触发原有规划弹窗。过期横幅从页面移除，控制器继续负责规划状态和时间持久化。

## 2026-11-16 · 日程窄屏标题与日期滚动

日程保留紧凑的月份／学期标题和原有三个操作。320 dp、1.3 倍字号的截图发现，当月历占满高度后，当天说明会在固定高度的列中溢出。月份标题按年月单位换行，月历和当天日程位于同一个纵向滚动区，顶栏保留在原处。已验证原有月／周切换手势和课程表切换。

## 2026-11-16 · Android 图标复用原生矢量

用同一个求是蓝时钟矢量作为 Android Adaptive Icon 的前景及系统启动标记。深浅背景由 Android 资源限定符选择，Android 12 及以上使用系统 Splash Screen，API 28–30 使用启动窗口图层。启动图标为静态，由系统在首帧就绪时交接。 [Android 自适应图标规范](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) [Android 启动页规范](https://developer.android.com/develop/ui/views/launch/splash-screen)

## 2026-11-16 · Android 平板侧栏使用窗口尺寸

开启 Liquid Glass 时，横屏窗口宽度至少 840 dp 且高度至少 480 dp 使用紧凑侧栏，宽度达到 1200 dp 时显示文字。侧栏使用一个玻璃容器，沿用同一 `PageView`、标签定义和回调。紧凑侧栏在同一个无障碍节点上提供标签、点击动作和选中状态。 [Android 窗口尺寸等级](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes)

日程双栏依据侧栏和安全区扣除后的实际内容空间，Android 横屏下宽度至少 760 dp、高度至少 420 dp 时并排显示月历与当天事项。两种布局复用同一日历、选日状态、事项列表和原有编辑路由。

## 2026-11-16 · Edition Android 打包与证书核验

目标 Fork 的 `edition-android-v*` 标签触发打包。工作流先检查标签提交来自 `liquid-glass`，再使用固定工具链、锁文件及 Edition 签名构建三个 ABI。每个 APK 通过 `apksigner` 并匹配预登记的证书 SHA-256 后，工作流才保存产物。标签触发让打包配置随 Edition 分支维护。 [GitHub Actions 触发事件](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) [Android apksigner](https://developer.android.com/tools/apksigner)

签名通过目标 Fork 的 Actions secrets 配置 `EDITION_ANDROID_KEYSTORE_BASE64`、`EDITION_ANDROID_STORE_PASSWORD`、`EDITION_ANDROID_KEY_ALIAS` 和 `EDITION_ANDROID_KEY_PASSWORD`。在 Actions variables 配置 `EDITION_ANDROID_SIGNING_SHA256` 为 64 个十六进制字符的证书指纹。工作流只在打包步骤中读取密钥和密码，临时文件随打包步骤结束清理。 [GitHub Actions secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)

本机默认构建继续使用开发签名。设置 `CELECHRON_RELEASE_SIGNING_REQUIRED` 会要求提供完整的 Edition 签名参数，缺失时 Gradle 直接退出。项目忽略常见密钥库文件，正式签名材料应在工作区之外保存。

本次分 ABI 构建的版本代码分别为 arm64-v8a 的 2001、armeabi-v7a 的 1001、x86_64 的 4001。正式迭代继续沿用同一分包策略，升级验证比较同一 ABI 的 APK 版本代码和证书。

## 2026-11-17 · 保留底栏完整触摸反馈

整套主页面和二级导航改造后的 Profile APK 在 API 37.1 x86_64 模拟器上重复 32 次同序列切页。完整玻璃反馈两次 Raster P95 为 175.47、169.73 ms。仅保留弹性反馈的方案为 190.71 ms，故撤回该试验。关闭总开关时，原有 Cupertino 外观的 Raster P95 为 5.33 ms。该对照同时切换底栏和页面操作控件，发布前仍需用物理设备测量真实帧时间。

## 2026-11-17 · 浮动底栏视口与日程滚动

首页的玻璃底栏叠在页面视口上。每页把底栏高度和系统底部安全区留在滚动内容末尾，列表经过底栏时仍有内容可供玻璃采样。关闭玻璃时沿用 Cupertino 自己的安全区。

用户要求月历固定，取代 11 月 16 日的月历随列表纵向滚动方案。手机月历按可用高度压缩日期行，当天事项单独纵向滚动。横屏双栏继续让日期区和事项区分别滚动。
