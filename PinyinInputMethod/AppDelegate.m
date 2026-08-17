/*
 * PinyinInputMethod - macOS 西蒙输入�?
 * AppDelegate.m - 应用代理实现
 */

#import "AppDelegate.h"
#import "InputController.h"
#import "DictionaryManager.h"
#import "StatusBarItem.h"
#import "ConfigManager.h"
#import "InstallationGuide.h"

static AppDelegate *sharedInstance = nil;

// 输入法服务器连接名称
static NSString * const kConnectionName = @"com.ximeng.inputmethod.connection";

@implementation AppDelegate

#pragma mark - 生命周期

+ (instancetype)sharedAppDelegate {
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        sharedInstance = self;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"[PinyinInputMethod] 应用启动�?..");
    
    // 初始化配置管理器
    [[ConfigManager sharedManager] loadConfig];
    
    // 初始化词库管理器
    _dictionaryManager = [[DictionaryManager alloc] init];
    [_dictionaryManager initializeDatabases];
    
    // 创建输入法服务器
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    _server = [[IMKServer alloc] initWithName:kConnectionName
                             bundleIdentifier:bundleID];
    
    if (_server) {
        NSLog(@"[PinyinInputMethod] 输入法服务器已成功启�?);
        NSLog(@"[PinyinInputMethod] Bundle ID: %@", bundleID);
        NSLog(@"[PinyinInputMethod] 连接名称: %@", kConnectionName);
    } else {
        NSLog(@"[PinyinInputMethod] 错误：无法启动输入法服务器！");
        return;
    }
    
    // 初始化状态栏图标
    _statusBarItem = [[StatusBarItem alloc] initWithServer:_server];
    [_statusBarItem setupStatusBar];
    
    // 首次运行时显示安装引�?
    if ([InstallationGuide shouldShowGuide]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            InstallationGuide *guide = [[InstallationGuide alloc] init];
            [guide showWindow:nil];
        });
    }
    
    NSLog(@"[PinyinInputMethod] 初始化完�?);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"[PinyinInputMethod] 应用即将退�?);
    
    // 保存配置
    [[ConfigManager sharedManager] saveConfig];
    
    // 关闭数据�?
    [_dictionaryManager closeDatabases];
    
    // 清理状态栏
    [_statusBarItem tearDown];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    // 输入法不应在关闭窗口后退�?
    return NO;
}

#pragma mark - 菜单动作

- (void)showPreferences:(id)sender {
    // 通过状态栏或直接打开偏好设置窗口
    NSWindowController *prefWC = [[NSWindowController alloc] 
        initWithWindowNibName:@"PreferencesWindow"];
    [prefWC showWindow:nil];
}

- (void)quitInputMethod:(id)sender {
    // 保存当前状�?
    [[ConfigManager sharedManager] saveConfig];
    
    // 退出应�?
    [NSApp terminate:self];
}

#pragma mark - 菜单构建

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"西蒙输入�?];
    
    [menu addItemWithTitle:@"偏好设置..." 
                    action:@selector(showPreferences:) 
             keyEquivalent:@","];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    [menu addItemWithTitle:@"退出西蒙输入法" 
                    action:@selector(quitInputMethod:) 
             keyEquivalent:@"q"];
    
    return menu;
}

@end
