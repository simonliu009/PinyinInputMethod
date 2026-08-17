/*
 * PinyinInputMethod - macOS 拼音输入法
 * AppDelegate.h - 应用代理头文件
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@class CandidateWindow;
@class StatusBarItem;
@class DictionaryManager;

@interface AppDelegate : NSObject <NSApplicationDelegate>

/// 输入法服务器实例
@property (nonatomic, strong) IMKServer *server;

/// 状态栏管理器
@property (nonatomic, strong) StatusBarItem *statusBarItem;

/// 词库管理器
@property (nonatomic, strong) DictionaryManager *dictionaryManager;

/// 获取全局单例
+ (instancetype)sharedAppDelegate;

/// 显示偏好设置窗口
- (void)showPreferences:(id)sender;

/// 退出输入法
- (void)quitInputMethod:(id)sender;

@end
