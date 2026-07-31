# Flutter 多媒体工具箱

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android">
  <a href="https://github.com/tianmen15/fgpt/releases">
    <img src="https://img.shields.io/github/v/release/tianmen15/fgpt?label=APK%20%E4%B8%8B%E8%BD%BD" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/功能数量-55%2B-orange" alt="Features">
</p>

一个基于 Flutter 开发的**全功能多媒体工具箱**应用，集成视频播放、音乐播放（均衡器+歌词）、壁纸系统、随机图片、以及 55+ 实用工具，追求功能全面但不臃肿。

---

## 📥 下载安装

👉 **[点击下载最新版 APK](https://github.com/tianmen15/fgpt/releases/latest)**

所有版本请查看 [Releases 页面](https://github.com/tianmen15/fgpt/releases)。

---

## ✨ 功能总览

| 模块 | 核心能力 |
|------|----------|
| 🎬 视频播放 | 本地/网络视频、手势控制（亮度/音量/进度）、全屏模式 |
| 🎵 音乐播放 | 在线搜索、10段EQ均衡器、频谱可视化、Apple Music风格歌词、播放列表 |
| 🖼️ 壁纸系统 | 本地图片、网络链接、每日API壁纸、自定义参数 |
| 🎨 随机图片 | Lolicon / LoremFlickr / TheCatAPI、自定义API与参数、下载收藏 |
| 🛠️ 55+ 工具 | 计算器、二维码、天气、笔记、下载管理、文件管理、编解码等 |

---

## 🎬 视频播放器

- **播放源**：本地视频文件 + 网络视频 URL
- **手势控制**：
  - 左侧上下滑动 → 调节亮度
  - 右侧上下滑动 → 调节音量
  - 水平左右滑动 → 快进/快退调节进度
- **防卡死**：异步初始化、60秒超时、重试机制、本地文件自动回退
- **支持格式**：MP4、MKV、AVI、MOV、WMV 等主流格式

---

## 🎵 音乐播放器

### 均衡器 (EQ)
- **10 段频率调节**：31Hz / 62Hz / 125Hz / 250Hz / 500Hz / 1kHz / 2kHz / 4kHz / 8kHz / 16kHz
- **预设模式**：流行 / 摇滚 / 古典 / 爵士 / 舞曲 / 人声 / 重低音 / 自定义
- **增益范围**：-12dB ~ +12dB

### 歌词显示
- Apple Music 风格全屏大字歌词
- 逐行高亮滚动，实时同步播放进度
- 支持 LRC 时间戳格式解析

### 频谱可视化
- 实时 FFT 频谱柱状动画
- 随音乐节奏动态变化

### 其他
- 网易云音乐搜索接口
- 播放列表管理（增删改查）
- 播放历史记录
- 循环 / 随机 / 单曲模式

---

## 🖼️ 壁纸系统

- **本地图片**：从相册选择图片设为壁纸
- **网络图片**：输入任意图片 URL 作为壁纸
- **每日 API**：Bing 每日一图 / Unsplash / 自定义 API
- **自定义参数**：可配置 API 地址、请求方式、Headers、JSON 路径
- **持久化**：所有壁纸配置保存在本地

---

## 🎨 随机图片

### 内置 API
| 源 | 说明 |
|----|------|
| Lolicon | ACG 二次元图片，支持 R18/关键词/画师筛选 |
| LoremFlickr | 真实摄影图库，支持关键词分类 |
| TheCatAPI | 猫咪图片集合 |

### 自定义 API
- 支持任意 GET 请求接口
- 可配置参数（如分类、数量、尺寸）
- 自动提取 JSON 响应中的图片 URL
- 下载到本地 / 加入收藏 / 设为壁纸

---

## 🛠️ 55+ 实用工具

### 计算类
- 计算器（标准型）
- 年龄计算器
- BMI 身体质量指数
- 单位换算（长度/重量/温度/面积/体积）

### 编解码类
- URL 编码 / 解码
- Base64 编码 / 解码
- JSON 格式化 / 压缩
- HEX / RGB / HSL 颜色格式转换

### 文本类
- 文本统计（字符/单词/行数）
- 正则表达式测试器
- 密码生成器（自定义长度与字符集）
- 大小写 / 反转 / 去空格

### 生成类
- 二维码生成
- 二维码扫描（通过相机）
- 随机配色方案生成
- UUID 生成

### 生活类
- 天气查询（城市搜索）
- 倒计时 / 秒表
- 笔记 / 备忘录
- 下载管理
- 文件管理器
- 历史记录中心（浏览/搜索/清除）

……以及更多！

---

## 🧱 技术架构

```
lib/
├── main.dart                     # 应用入口
├── models/
│   └── models.dart               # 数据模型
├── screens/                      # 各功能页面
│   ├── home_screen.dart          # 主页导航
│   ├── player_screen.dart        # 视频播放
│   ├── music_screen.dart         # 音乐搜索
│   ├── music_player_screen.dart  # 音乐播放器（EQ/歌词）
│   ├── wallpaper_screen.dart     # 壁纸设置
│   ├── image_screen.dart         # 图片获取
│   ├── tools_screen.dart         # 工具集合
│   └── ...                       # 其他页面
├── services/                     # 业务服务
│   ├── music_service.dart        # 音乐 API & 播放
│   ├── image_service.dart        # 图片 API 集成
│   ├── storage_service.dart      # 本地持久化
│   └── lolicon_service.dart      # 图库 API
└── widgets/
    └── wallpaper_scaffold.dart   # 可换肤脚手架
```

### 主要依赖
| 插件 | 用途 |
|------|------|
| `video_player` | 视频播放核心 |
| `just_audio` / `just_audio_background` | 音乐播放 + 后台播放 |
| `audio_session` | 音频焦点管理 |
| `image_picker` | 本地图片选择 |
| `shared_preferences` | 本地存储 |
| `http` | 网络请求 |
| `connectivity_plus` | 网络状态 |
| `device_info_plus` | 设备信息 |
| `qr_flutter` / `mobile_scanner` | 二维码生成与扫描 |
| `flutter_tts` | 文字转语音 |

---

## 🚀 本地构建

### 环境要求
- Flutter SDK 3.x
- Android SDK (API 21+)
- Java 17（Gradle 构建用）

### 构建命令
```bash
# 获取依赖
flutter pub get

# Debug 运行
flutter run

# Release APK 构建
flutter build apk --release
```

### Gradle 国内镜像
已在 `android/settings.gradle` 与 `android/build.gradle` 中配置阿里云镜像（google / central / public），国内构建无需翻墙。

---

## 📄 License

本项目仅供学习与个人使用。
