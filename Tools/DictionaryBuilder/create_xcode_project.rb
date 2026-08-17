#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# PinyinInputMethod - Xcode 项目自动生成脚本
# create_xcode_project.rb
#
# 在 macOS 上运行此脚本自动生成 .xcodeproj 项目文件
# 用法: ruby create_xcode_project.rb
#
# 依赖: xcodeproj gem (macOS 自带，也可 sudo gem install xcodeproj)

require 'xcodeproj'

PROJECT_NAME = 'PinyinInputMethod'
BUNDLE_ID = 'com.pinyin.inputmethod'
DEPLOYMENT_TARGET = '11.0'
SRC_ROOT = File.join(__dir__, '..', 'PinyinInputMethod')

def create_project
  puts "=" * 60
  puts "PinyinInputMethod - Xcode 项目生成器"
  puts "=" * 60

  # 创建项目
  project = Xcodeproj::Project.new("#{PROJECT_NAME}.xcodeproj")

  # 主 target
  target = project.new_target(:application, PROJECT_NAME, :osx, DEPLOYMENT_TARGET)
  target.product_type = 'com.apple.product-type.tool'

  # 设置 Build Settings
  target.build_configurations.each do |config|
    settings = config.build_settings
    settings['PRODUCT_NAME'] = PROJECT_NAME
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
    settings['MACOSX_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    settings['INFOPLIST_FILE'] = 'PinyinInputMethod/Info.plist'
    settings['CODE_SIGN_ENTITLEMENTS'] = 'PinyinInputMethod/PinyinInputMethod.entitlements'
    settings['CODE_SIGN_IDENTITY'] = '-'
    settings['CODE_SIGN_STYLE'] = 'Manual'
    settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)']
    settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
    settings['HEADER_SEARCH_PATHS'] = [
      '$(inherited)',
      '$(SRCROOT)/PinyinInputMethod',
      '$(SRCROOT)/PinyinInputMethod/PinyinEngine',
      '$(SRCROOT)/PinyinInputMethod/Dictionary',
      '$(SRCROOT)/PinyinInputMethod/UI',
      '$(SRCROOT)/PinyinInputMethod/Utils',
    ]
    settings['OTHER_LDFLAGS'] = [
      '-framework', 'Cocoa',
      '-framework', 'InputMethodKit',
      '-framework', 'Carbon',
      '-lsqlite3',
    ]
    settings['GCC_INPUT_ENCODING'] = 'UTF-8'
  end

  # ===== 添加源文件 =====
  puts "\n添加源文件..."

  source_files = [
    # 入口与核心
    'PinyinInputMethod/main.m',
    'PinyinInputMethod/AppDelegate.m',
    'PinyinInputMethod/InputController.m',
    # 拼音引擎
    'PinyinInputMethod/PinyinEngine/PinyinEngine.m',
    'PinyinInputMethod/PinyinEngine/PinyinParser.m',
    'PinyinInputMethod/PinyinEngine/CandidateRanker.m',
    'PinyinInputMethod/PinyinEngine/FuzzyMatcher.m',
    # 词库
    'PinyinInputMethod/Dictionary/DictionaryManager.m',
    'PinyinInputMethod/Dictionary/DictionaryDB.m',
    'PinyinInputMethod/Dictionary/SogouSCelParser.m',
    'PinyinInputMethod/Dictionary/UserDictionary.m',
    # UI
    'PinyinInputMethod/UI/CandidateWindow.m',
    'PinyinInputMethod/UI/CandidateCell.m',
    'PinyinInputMethod/UI/StatusBarItem.m',
    'PinyinInputMethod/UI/PreferencesWindow.m',
    'PinyinInputMethod/UI/InstallationGuide.m',
    # 工具
    'PinyinInputMethod/Utils/ConfigManager.m',
    'PinyinInputMethod/Utils/StringHelper.m',
  ]

  source_files.each do |path|
    full_path = File.join(__dir__, '..', path)
    if File.exist?(full_path)
      ref = project.main_group.new_reference(path)
      target.source_build_phase.add_file_reference(ref)
      puts "  ✓ #{path}"
    else
      puts "  ✗ #{path} (文件不存在)"
    end
  end

  # ===== 添加头文件（用于索引） =====
  puts "\n添加头文件..."

  header_files = [
    'PinyinInputMethod/AppDelegate.h',
    'PinyinInputMethod/InputController.h',
    'PinyinInputMethod/PinyinEngine/PinyinEngine.h',
    'PinyinInputMethod/PinyinEngine/PinyinParser.h',
    'PinyinInputMethod/PinyinEngine/CandidateRanker.h',
    'PinyinInputMethod/PinyinEngine/FuzzyMatcher.h',
    'PinyinInputMethod/Dictionary/DictionaryManager.h',
    'PinyinInputMethod/Dictionary/DictionaryDB.h',
    'PinyinInputMethod/Dictionary/SogouSCelParser.h',
    'PinyinInputMethod/Dictionary/UserDictionary.h',
    'PinyinInputMethod/UI/CandidateWindow.h',
    'PinyinInputMethod/UI/CandidateCell.h',
    'PinyinInputMethod/UI/StatusBarItem.h',
    'PinyinInputMethod/UI/PreferencesWindow.h',
    'PinyinInputMethod/UI/InstallationGuide.h',
    'PinyinInputMethod/Utils/ConfigManager.h',
    'PinyinInputMethod/Utils/StringHelper.h',
  ]

  header_files.each do |path|
    full_path = File.join(__dir__, '..', path)
    if File.exist?(full_path)
      ref = project.main_group.new_reference(path)
      puts "  ✓ #{path}"
    else
      puts "  ✗ #{path} (文件不存在)"
    end
  end

  # ===== 添加资源文件 =====
  puts "\n添加资源文件..."

  resource_files = [
    'PinyinInputMethod/Resources/pinyin_map.txt',
    'PinyinInputMethod/Resources/pinyin_base.db',
    'PinyinInputMethod/Resources/Assets.xcassets',
    'PinyinInputMethod/Info.plist',
    'PinyinInputMethod/PinyinInputMethod.entitlements',
  ]

  resource_files.each do |path|
    full_path = File.join(__dir__, '..', path)
    if File.exist?(full_path)
      ref = project.main_group.new_reference(path)
      target.resources_build_phase.add_file_reference(ref)
      puts "  ✓ #{path}"
    else
      puts "  ✗ #{path} (文件不存在)"
    end
  end

  # ===== 链接框架 =====
  puts "\n链接框架..."

  framework_names = ['Cocoa', 'InputMethodKit', 'Carbon']
  framework_names.each do |fw|
    fw_ref = project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework")
    target.frameworks_build_phase.add_file_reference(fw_ref)
    puts "  ✓ #{fw}.framework"
  end

  # sqlite3 (动态库)
  lib_ref = project.frameworks_group.new_file("usr/lib/libsqlite3.tbd")
  target.frameworks_build_phase.add_file_reference(lib_ref)
  puts "  ✓ libsqlite3.tbd"

  # ===== 创建项目分组结构 =====
  puts "\n整理项目结构..."

  # 为源码创建逻辑分组
  main_group = project.main_group

  # 创建子分组
  engine_group = main_group.new_group('PinyinEngine', 'PinyinInputMethod/PinyinEngine')
  dict_group = main_group.new_group('Dictionary', 'PinyinInputMethod/Dictionary')
  ui_group = main_group.new_group('UI', 'PinyinInputMethod/UI')
  utils_group = main_group.new_group('Utils', 'PinyinInputMethod/Utils')
  resources_group = main_group.new_group('Resources', 'PinyinInputMethod/Resources')

  # ===== 保存项目 =====
  puts "\n保存项目..."
  project.save
  puts "  ✓ #{PROJECT_NAME}.xcodeproj"

  puts "\n" + "=" * 60
  puts "✅ Xcode 项目创建完成！"
  puts "=" * 60
  puts ""
  puts "下一步："
  puts "  1. 双击打开 #{PROJECT_NAME}.xcodeproj"
  puts "  2. 按 ⌘+B 编译"
  puts "  3. 编译产物在 build/ 目录"
  puts ""
  puts "安装到系统："
  puts "  sudo cp -R build/#{PROJECT_NAME}.app '/Library/Input Methods/'"
  puts ""

  # 同时生成 scheme
  puts "创建运行 Scheme..."
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(target)
  scheme.save_as("#{PROJECT_NAME}.xcodeproj", PROJECT_NAME)
  puts "  ✓ Scheme: #{PROJECT_NAME}"

  puts "\n全部完成！可以用 Xcode 打开项目了。"
end

create_project
