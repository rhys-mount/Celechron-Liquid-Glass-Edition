# Celechron Liquid Glass Edition

<p align="center">
  <img src="./banner.png" alt="Celechron" width="80%">
</p>

服务于浙大学生的时间管理器 · 日程一览 · 课表查看 · DDL 助手 · 成绩查询

基于官方 Celechron 的 Android 界面适配版。由 **rhys-mount** 维护，参考 Apple Liquid Glass 的导航与控件样式，沿用官方的课程、成绩、日程和任务功能。

## 📦 下载与安装

需要 **Android 9 或更高版本**。大多数 Android 手机请选择 **ARM64**。

| 设备 | 安装包 |
| --- | --- |
| 大多数 Android 手机和平板 | [下载 ARM64 APK](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/releases/latest/download/Celechron-Liquid-Glass-Edition-arm64-v8a.apk) |
| 仅支持 32 位 ARM 的设备 | [下载 ARMv7 APK](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/releases/latest/download/Celechron-Liquid-Glass-Edition-armeabi-v7a.apk) |
| x86-64 Android 设备和模拟器 | [下载 x86-64 APK](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/releases/latest/download/Celechron-Liquid-Glass-Edition-x86_64.apk) |

[查看最新正式版与校验文件](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/releases/latest)

本仓库发布的 `1.3.1-preview.2` 可直接覆盖升级。官方 Celechron、早期独立仓库的版本及开发签名试用包使用不同签名，Android 无法直接覆盖。切换到 Edition 前，请先保存需要保留的本地数据。

## 🍷 Liquid Glass Edition

- 浮动底栏与顶部操作控件使用玻璃材质，课程、任务、成绩等内容区域以清晰阅读为主。
- 学业搜索从首页平滑上移并进入输入状态，学业、课程、考试和课表使用统一的悬浮学期筛选样式。
- 接下来、日程、成绩、课程和课表统一课程详情转场。课程卡右侧集中显示学分与成绩。
- 加权成绩可跨学期勾选课程，倍率控件包含 `1.1×`。课表和成绩标记随浅色、深色主题切换。
- 在「设置 → 外观」中可调整界面效果。校园卡小组件跟随主题色并简化余额展示。

## 🛠 构建

使用 Flutter `3.47.4`、JDK `17`、Android SDK `36` 和 NDK `28.2.13676358`。依赖按 `pubspec.lock` 解析。

```bash
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter run
```

发行 APK 需要 Edition 的签名配置。自行构建时若使用其他签名，生成的 APK 将具有不同的升级身份。

## 🔄 上游同步

| 分支 | 用途 |
| --- | --- |
| [`liquid-glass`](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/tree/liquid-glass) | 默认分支，维护 Edition 界面和发布版本 |
| [`main`](https://github.com/rhys-mount/Celechron-Liquid-Glass-Edition/tree/main) | 跟踪官方 Celechron 主分支 |

官方更新先快进同步到本仓库 `main`，再通过独立 PR 合入 `liquid-glass`，经测试和 Android 构建后发布。[官方 Celechron](https://github.com/Celechron/Celechron)

## 📜 署名与许可证

感谢 Celechron 的原作者与所有贡献者。制作人员可在应用内「设置 → 关于 Celechron」查看。Liquid Glass Edition 由 **rhys-mount** 适配维护，沿用原项目的 [GPL-3.0 许可证](LICENSE)。

[早期 Liquid Glass 适配仓库](https://github.com/rhys-mount/Celechron-1.3.1-liquid-glass)
