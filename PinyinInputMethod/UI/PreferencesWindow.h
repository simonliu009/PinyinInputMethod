/*
 * PinyinInputMethod - macOS 拼音输入法
 * PreferencesWindow.h - 偏好设置窗口
 */

#import <Cocoa/Cocoa.h>

@interface PreferencesWindow : NSWindowController <NSTabViewDelegate>

/// 标签页视图
@property (nonatomic, strong) IBOutlet NSTabView *tabView;

/// 初始化
- (instancetype)init;

@end
