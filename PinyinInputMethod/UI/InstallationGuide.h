/*
 * PinyinInputMethod - macOS 拼音输入法
 * InstallationGuide.h - 安装引导界面
 *
 * 首次运行时引导用户完成输入法安装配置
 */

#import <Cocoa/Cocoa.h>

@interface InstallationGuide : NSWindowController

/// 初始化
- (instancetype)init;

/// 检查是否需要显示安装引导
+ (BOOL)shouldShowGuide;

/// 标记安装引导已完成
+ (void)markGuideCompleted;

@end
