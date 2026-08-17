/*
 * PinyinInputMethod - macOS 拼音输入�?
 * InstallationGuide.h - 安装引导界面
 *
 * 首次运行时引导用户完成输入法安装配置
 */

#import <Cocoa/Cocoa.h>

@interface InstallationGuide : NSWindowController

/// 初始�?
- (instancetype)init;

/// 检查是否需要显示安装引�?
+ (BOOL)shouldShowGuide;

/// 标记安装引导已完�?
+ (void)markGuideCompleted;

@end
