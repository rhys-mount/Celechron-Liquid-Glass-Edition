# Celechron Liquid Glass Edition 技术决策

产品决策以 [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) 为准。以下记录实施中已采用的技术做法及其适用范围。

## 2026-11-16 · Android 原版基线验证使用独立模拟器

复用本机已安装的 Android 37.1 x86_64 系统镜像，创建 `Celechron_Isolated_API_37_1`。应用数据位于项目本地专用目录，测试通过固定的 `emulator-5564` 连接。这样可以用原版包名验证安装、启动和后续更新路径，并隔离日常设备与既有 AVD 的数据。手机兼容性与正式签名仍按需求基线验收。

API 36 验收使用同样隔离的 `Celechron_Isolated_API_36`（`emulator-5566`）。系统镜像来自 Google SDK 仓库，按其发布校验值核验。

## 2026-11-16 · 对齐 Android 构建工具链

采用 Flutter 3.47.4、JDK 17、Gradle 8.14.5 与 Kotlin／Compose 插件 2.2.20。原版构建日志确认 Gradle 8.13 未达到 Flutter 校验下限。保留 AGP 8.13.2、应用身份与最低 API 28。Gradle Wrapper 使用官方发行地址和 SHA-256，构建分支与官方 `main` 分开。

本机的依赖下载通过进程级配置让 Maven Central、Google Maven 和 Flutter Maven 存储直连。由于官方 Gradle 下载重定向在本机被拒绝，首次使用镜像预取，按官网 SHA-256 核对后放入同 URL 对应的 Wrapper 缓存。项目配置继续指向官方地址。
