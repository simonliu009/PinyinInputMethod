# 拼音输入法 (PinyinInputMethod)

一款基于 macOS Input Method Kit 框架开发的拼音输入法，支持导入搜狗输入法词库。

## 系统要求

- macOS 11.0 (Big Sur) 及以上
- Xcode 13 及以上

## 功能特性

- 智能拼音输入，支持多音字和词组
- 搜狗 .scel 词库导入
- 模糊音支持（z/zh, c/ch, s/sh, n/l, f/h, an/ang, en/eng, in/ing）
- 用户词频自适应学习
- 自定义短语（支持日期、时间等动态变量）
- 全角/半角切换
- 中英文快速切换（Shift）
- 候选词翻页和数字键快速选词
- 偏好设置界面

## 项目结构

```
PinyinInputMethod/
├── PinyinInputMethod/
│   ├── main.m                     # 程序入口
│   ├── AppDelegate.h/m            # 应用代理
│   ├── InputController.h/m        # IMK 输入控制器（核心）
│   ├── PinyinEngine/              # 拼音引擎
│   │   ├── PinyinEngine.h/m       # 引擎主类
│   │   ├── PinyinParser.h/m       # 拼音解析器
│   │   ├── CandidateRanker.h/m    # 候选词排序
│   │   └── FuzzyMatcher.h/m       # 模糊音匹配
│   ├── Dictionary/                # 词库模块
│   │   ├── DictionaryManager.h/m  # 词库管理器
│   │   ├── DictionaryDB.h/m       # SQLite 数据库
│   │   ├── SogouSCelParser.h/m    # 搜狗词库解析
│   │   └── UserDictionary.h/m     # 用户词库
│   ├── UI/                        # 界面模块
│   │   ├── CandidateWindow.h/m    # 候选词窗口
│   │   ├── CandidateCell.h/m      # 候选词单元格
│   │   ├── StatusBarItem.h/m      # 状态栏图标
│   │   └── PreferencesWindow.h/m  # 偏好设置
│   ├── Utils/                     # 工具模块
│   │   ├── StringHelper.h/m       # 字符串工具
│   │   └── ConfigManager.h/m      # 配置管理
│   └── Resources/
│       └── pinyin_map.txt         # 基础词库
└── Tools/
    └── DictionaryBuilder/
        └── build_dictionary.py    # 词库编译工具
```

## 在 macOS 上构建

### 步骤 1：创建 Xcode 项目

1. 打开 Xcode
2. File → New → Project
3. 选择 **macOS → Input Method**
4. 填写：
   - Product Name: `PinyinInputMethod`
   - Language: `Objective-C`
   - Minimum Deployment: `macOS 11.0`
   - Bundle Identifier: `com.pinyin.inputmethod`

### 步骤 2：添加源文件

将本项目 `PinyinInputMethod/PinyinInputMethod/` 目录下的所有文件拖入 Xcode 项目中。

### 步骤 3：链接框架

在 Target → General → Frameworks and Libraries 中添加：
- `Cocoa.framework`
- `InputMethodKit.framework`
- `libsqlite3.tbd`

### 步骤 4：配置 Info.plist

使用本项目的 `Info.plist` 替换 Xcode 生成的文件，或手动添加以下键值：
- `InputMethodConnectionName`: `com.pinyin.inputmethod.connection`
- `InputMethodServerControllerClass`: `InputController`
- `LSBackgroundOnly`: `YES`
- `tsInputModeListKey`: （见 Info.plist 文件）

### 步骤 5：编译运行

按 Cmd+B 编译项目。

## 安装输入法

1. 编译成功后，在 Products 中找到 `PinyinInputMethod.app`
2. 将 `.app` 复制到 `/Library/Input Methods/` 或 `~/Library/Input Methods/`
3. 打开 **系统偏好设置 → 键盘 → 输入法**
4. 点击 "+" 添加 "拼音输入法"
5. 在菜单栏的输入法图标中切换到本输入法

## 导入搜狗词库

1. 从搜狗输入法官网下载 .scel 格式的词库文件
2. 点击菜单栏输入法图标 → "导入搜狗词库..."
3. 选择 .scel 文件
4. 等待导入完成

## 搜狗 .scel 文件格式

本输入法支持解析搜狗输入法的自定义词库文件（.scel 格式），文件格式如下：

| 区域 | 偏移 | 说明 |
|------|------|------|
| 文件头 | 0x00 - 0x3F | 包含文件标识、版本等 |
| 信息区 | 0x40 - 0x11F | 词库名称、作者、描述 |
| 拼音表 | 0x120 - 0x261F | 拼音索引表 |
| 词条区 | 0x2620+ | 词组数据（UTF-16LE 编码）|

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| Shift | 切换中/英文模式 |
| Space | 确认第一个候选词 |
| Enter | 提交拼音原文 |
| Backspace | 删除最后一个字母 |
| Escape | 取消当前输入 |
| 1-9 | 选择对应序号的候选词 |
| [ / ] | 上/下翻页 |

## 自定义短语

支持通过触发键自动展开预设内容：

| 触发键 | 展开内容 | 说明 |
|--------|----------|------|
| rq | 2026年08月17日 | 当前日期 |
| sj | 14:30:00 | 当前时间 |
| xq | 星期一 | 当前星期 |
| dt | 2026-08-17 14:30:00 | 日期时间 |

## 许可证

本项目仅供学习和个人使用。
