/*
 * PinyinInputMethod - macOS 拼音输入法
 * StatusBarItem.h - 状态栏图标
 *
 * 在系统菜单栏显示输入法状态图标和菜单
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@interface StatusBarItem : NSObject

/// 状态栏项
@property (nonatomic, strong) NSStatusItem *statusItem;

/// 输入法服务器
@property (nonatomic, strong) IMKServer *server;

/// 初始化
- (instancetype)initWithServer:(IMKServer *)server;

/// 设置状态栏
- (void)setupStatusBar;

/// 更新状态图标（中/英文模式）
- (void)updateStatusIcon;

/// 清理状态栏
- (void)tearDown;

@end
