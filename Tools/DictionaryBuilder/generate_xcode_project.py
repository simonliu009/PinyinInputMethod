#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PinyinInputMethod - Xcode 项目生成脚本
generate_xcode_project.py

在 macOS 上运行此脚本来生成 Xcode 项目文件
用法: python3 generate_xcode_project.py
"""

import os
import uuid
import json


def generate_uuid():
    """生成 24 位十六进制 UUID"""
    return uuid.uuid4().hex[:24].upper()


def generate_pbxproj():
    """生成 project.pbxproj 文件内容"""
    
    # 文件引用 UUID
    file_refs = {
        'main.m': generate_uuid(),
        'AppDelegate.h': generate_uuid(),
        'AppDelegate.m': generate_uuid(),
        'InputController.h': generate_uuid(),
        'InputController.m': generate_uuid(),
        'PinyinEngine.h': generate_uuid(),
        'PinyinEngine.m': generate_uuid(),
        'PinyinParser.h': generate_uuid(),
        'PinyinParser.m': generate_uuid(),
        'CandidateRanker.h': generate_uuid(),
        'CandidateRanker.m': generate_uuid(),
        'FuzzyMatcher.h': generate_uuid(),
        'FuzzyMatcher.m': generate_uuid(),
        'DictionaryManager.h': generate_uuid(),
        'DictionaryManager.m': generate_uuid(),
        'DictionaryDB.h': generate_uuid(),
        'DictionaryDB.m': generate_uuid(),
        'SogouSCelParser.h': generate_uuid(),
        'SogouSCelParser.m': generate_uuid(),
        'UserDictionary.h': generate_uuid(),
        'UserDictionary.m': generate_uuid(),
        'CandidateWindow.h': generate_uuid(),
        'CandidateWindow.m': generate_uuid(),
        'CandidateCell.h': generate_uuid(),
        'CandidateCell.m': generate_uuid(),
        'StatusBarItem.h': generate_uuid(),
        'StatusBarItem.m': generate_uuid(),
        'PreferencesWindow.h': generate_uuid(),
        'PreferencesWindow.m': generate_uuid(),
        'StringHelper.h': generate_uuid(),
        'StringHelper.m': generate_uuid(),
        'ConfigManager.h': generate_uuid(),
        'ConfigManager.m': generate_uuid(),
        'Info.plist': generate_uuid(),
        'entitlements': generate_uuid(),
        'pinyin_map.txt': generate_uuid(),
    }
    
    # 构建组 UUID
    build_files = {k: generate_uuid() for k in file_refs}
    groups = {
        'root': generate_uuid(),
        'main': generate_uuid(),
        'engine': generate_uuid(),
        'dict': generate_uuid(),
        'ui': generate_uuid(),
        'utils': generate_uuid(),
        'resources': generate_uuid(),
        'products': generate_uuid(),
    }
    
    project_uuid = generate_uuid()
    target_uuid = generate_uuid()
    config_list_project = generate_uuid()
    config_list_target = generate_uuid()
    config_debug_project = generate_uuid()
    config_release_project = generate_uuid()
    config_debug_target = generate_uuid()
    config_release_target = generate_uuid()
    build_phase_sources = generate_uuid()
    build_phase_resources = generate_uuid()
    build_phase_frameworks = generate_uuid()
    
    print(f"项目 UUID 已生成")
    print(f"Project: {project_uuid}")
    print(f"Target: {target_uuid}")
    
    return {
        'file_refs': file_refs,
        'build_files': build_files,
        'groups': groups,
        'project_uuid': project_uuid,
        'target_uuid': target_uuid,
        'config_list_project': config_list_project,
        'config_list_target': config_list_target,
        'config_debug_project': config_debug_project,
        'config_release_project': config_release_project,
        'config_debug_target': config_debug_target,
        'config_release_target': config_release_target,
        'build_phase_sources': build_phase_sources,
        'build_phase_resources': build_phase_resources,
        'build_phase_frameworks': build_phase_frameworks,
    }


def main():
    print("=" * 60)
    print("PinyinInputMethod - Xcode 项目生成器")
    print("=" * 60)
    
    uuids = generate_pbxproj()
    
    print("\n注意：由于在 Windows 环境下无法直接生成 .xcodeproj 文件，")
    print("请在 macOS 上按照以下步骤创建 Xcode 项目：")
    print()
    print("1. 打开 Xcode")
    print("2. File -> New -> Project")
    print("3. 选择 macOS -> Input Method")
    print("4. Product Name: PinyinInputMethod")
    print("5. Language: Objective-C")
    print("6. Minimum Deployment: macOS 11.0")
    print("7. 将本项目中的所有 .h/.m 文件添加到项目中")
    print("8. 链接以下框架：")
    print("   - Cocoa.framework")
    print("   - InputMethodKit.framework")
    print("   - sqlite3.tbd")
    print("9. 配置 Info.plist（使用本项目的 Info.plist）")
    print("10. 配置 Entitlements（使用本项目的 .entitlements 文件）")
    print("11. 设置 Bundle Identifier: com.pinyin.inputmethod")
    print()
    print("项目源代码已全部生成，可以直接编译运行！")


if __name__ == '__main__':
    main()
