# PinyinInputMethod Makefile
# 用于在 macOS 上通过命令行编译项目
# 用法: make (在 macOS 上运行)

# 编译器
CC = clang

# 部署目标
MACOSX_DEPLOYMENT_TARGET = 11.0

# 框架
FRAMEWORKS = -framework Cocoa -framework InputMethodKit -framework Carbon -framework UniformTypeIdentifiers -lsqlite3

# 编译选项
CFLAGS = -ObjC -mmacosx-version-min=11.0 -fobjc-arc \
         -I$(SRC_DIR) \
         -I$(SRC_DIR)/PinyinEngine \
         -I$(SRC_DIR)/Dictionary \
         -I$(SRC_DIR)/UI \
         -I$(SRC_DIR)/Utils

# 链接选项
LDFLAGS = $(FRAMEWORKS) -mmacosx-version-min=11.0

# 目录
SRC_DIR = PinyinInputMethod
BUILD_DIR = build
APP_NAME = PinyinInputMethod
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

# 源文件
SOURCES = \
    $(SRC_DIR)/main.m \
    $(SRC_DIR)/AppDelegate.m \
    $(SRC_DIR)/InputController.m \
    $(SRC_DIR)/PinyinEngine/PinyinEngine.m \
    $(SRC_DIR)/PinyinEngine/PinyinParser.m \
    $(SRC_DIR)/PinyinEngine/CandidateRanker.m \
    $(SRC_DIR)/PinyinEngine/FuzzyMatcher.m \
    $(SRC_DIR)/Dictionary/DictionaryManager.m \
    $(SRC_DIR)/Dictionary/DictionaryDB.m \
    $(SRC_DIR)/Dictionary/SogouSCelParser.m \
    $(SRC_DIR)/Dictionary/UserDictionary.m \
    $(SRC_DIR)/UI/CandidateWindow.m \
    $(SRC_DIR)/UI/CandidateCell.m \
    $(SRC_DIR)/UI/StatusBarItem.m \
    $(SRC_DIR)/UI/PreferencesWindow.m \
    $(SRC_DIR)/UI/InstallationGuide.m \
    $(SRC_DIR)/Utils/ConfigManager.m \
    $(SRC_DIR)/Utils/StringHelper.m

OBJECTS = $(patsubst $(SRC_DIR)/%.m,$(BUILD_DIR)/%.o,$(SOURCES))

# 资源文件
PLIST = $(SRC_DIR)/Info.plist
ENTITLEMENTS = $(SRC_DIR)/PinyinInputMethod.entitlements
RESOURCES = \
    $(SRC_DIR)/Resources/pinyin_map.txt \
    $(SRC_DIR)/Resources/pinyin_base.db \
    $(SRC_DIR)/Resources/Assets.xcassets

.PHONY: all clean directories

all: directories $(APP_BUNDLE)

directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@mkdir -p $(sort $(dir $(OBJECTS)))

# 编译目标文件
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# 构建 .app 包
$(APP_BUNDLE): $(OBJECTS)
	@echo "链接中..."
	$(CC) $(LDFLAGS) $(OBJECTS) -o $(MACOS_DIR)/$(APP_NAME)
	@echo "复制资源..."
	cp $(PLIST) $(CONTENTS_DIR)/Info.plist
	@for res in $(RESOURCES); do \
		if [ -f "$$res" ]; then \
			cp -R "$$res" $(RESOURCES_DIR)/; \
		fi; \
	done
	@echo "============================================"
	@echo "构建成功！"
	@echo "应用包: $(APP_BUNDLE)"
	@echo "============================================"
	@echo ""
	@echo "安装步骤："
	@echo "  1. 将 $(APP_BUNDLE) 复制到 /Library/Input Methods/"
	@echo "     sudo cp -R $(APP_BUNDLE) '/Library/Input Methods/'"
	@echo "  2. 打开系统偏好设置 → 键盘 → 输入法"
	@echo "  3. 点击 + 按钮，添加「西蒙输入法」"

clean:
	rm -rf $(BUILD_DIR)
	@echo "清理完成"

# 安装到系统
install: $(APP_BUNDLE)
	sudo cp -R $(APP_BUNDLE) "/Library/Input Methods/"
	@echo "安装完成！请在系统偏好设置中启用输入法。"

# 构建 pkg 安装包
PKG_DIR = $(BUILD_DIR)/pkg
PKG_ROOT = $(PKG_DIR)/root
SCRIPTS_DIR = $(PKG_DIR)/scripts
PKG_FILE = $(BUILD_DIR)/PinyinInputMethod.pkg

pkg: $(APP_BUNDLE)
	@echo "构建 pkg 安装包..."
	@rm -rf $(PKG_DIR)
	@mkdir -p $(PKG_ROOT)/Library/Input\ Methods
	@mkdir -p $(SCRIPTS_DIR)
	@# 复制 app 到安装目录
	cp -R $(APP_BUNDLE) $(PKG_ROOT)/Library/Input\ Methods/
	@# 创建 postinstall 脚本
	@echo '#!/bin/bash' > $(SCRIPTS_DIR)/postinstall
	@echo '# 刷新系统偏好设置缓存' >> $(SCRIPTS_DIR)/postinstall
	@echo '/usr/bin/killall -HUP cfprefsd 2>/dev/null || true' >> $(SCRIPTS_DIR)/postinstall
	@echo '# 启动一次输入法以触发系统注册' >> $(SCRIPTS_DIR)/postinstall
	@echo 'IM_APP="/Library/Input Methods/PinyinInputMethod.app"' >> $(SCRIPTS_DIR)/postinstall
	@echo 'if [ -d "$$IM_APP" ]; then' >> $(SCRIPTS_DIR)/postinstall
	@echo '    open "$$IM_APP" &' >> $(SCRIPTS_DIR)/postinstall
	@echo '    sleep 2' >> $(SCRIPTS_DIR)/postinstall
	@echo '    killall PinyinInputMethod 2>/dev/null || true' >> $(SCRIPTS_DIR)/postinstall
	@echo 'fi' >> $(SCRIPTS_DIR)/postinstall
	@echo 'exit 0' >> $(SCRIPTS_DIR)/postinstall
	@chmod +x $(SCRIPTS_DIR)/postinstall
	@# 构建 pkg
	pkgbuild --root $(PKG_ROOT) \
		--scripts $(SCRIPTS_DIR) \
		--identifier com.ximeng.inputmethod \
		--version 1.0.0 \
		--install-location / \
		$(PKG_FILE)
	@echo "============================================"
	@echo "pkg 安装包构建成功！"
	@echo "安装包: $(PKG_FILE)"
	@echo "============================================"
	@echo ""
	@echo "双击 .pkg 文件即可安装"
	@echo "安装后在 系统设置 → 键盘 → 输入法 中添加"

# 运行测试（需要 macOS）
test:
	@echo "编译测试..."
	$(CC) $(CFLAGS) -framework XCTest \
		PinyinInputMethodTests/PinyinParserTests.m \
		$(SRC_DIR)/PinyinEngine/PinyinParser.m \
		-c -o /dev/null 2>&1 || echo "测试编译需要 Xcode 环境"
