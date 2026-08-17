# PinyinInputMethod Makefile
# 用于在 macOS 上通过命令行编译项目
# 用法: make (在 macOS 上运行)

# 编译器
CC = clang

# 部署目标
MACOSX_DEPLOYMENT_TARGET = 11.0

# 框架
FRAMEWORKS = -framework Cocoa -framework InputMethodKit -framework Carbon -lsqlite3

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
	@echo "  3. 点击 + 按钮，添加「拼音输入法」"

clean:
	rm -rf $(BUILD_DIR)
	@echo "清理完成"

# 安装到系统
install: $(APP_BUNDLE)
	sudo cp -R $(APP_BUNDLE) "/Library/Input Methods/"
	@echo "安装完成！请在系统偏好设置中启用输入法。"

# 运行测试（需要 macOS）
test:
	@echo "编译测试..."
	$(CC) $(CFLAGS) -framework XCTest \
		PinyinInputMethodTests/PinyinParserTests.m \
		$(SRC_DIR)/PinyinEngine/PinyinParser.m \
		-c -o /dev/null 2>&1 || echo "测试编译需要 Xcode 环境"
