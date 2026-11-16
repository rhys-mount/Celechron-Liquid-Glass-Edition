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

## 2026-11-16 · 顶部操作按钮共用外观策略

「接下来」保留 Cupertino 大标题及其滚动收缩。独立玻璃操作按钮共用外观总开关和 Shader 能力降级，使用同一回调触发原有规划弹窗。过期横幅从页面移除，控制器继续负责规划状态和时间持久化。
