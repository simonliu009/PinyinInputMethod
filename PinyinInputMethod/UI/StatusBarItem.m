/*
 * PinyinInputMethod - macOS 西蒙输入�?
 * StatusBarItem.m - 状态栏图标实现
 */

#import "StatusBarItem.h"
#import "ConfigManager.h"
#import "InputController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// 菜单动作标识
static NSString * const kActionToggleMode = @"toggleMode";
static NSString * const kActionPreferences = @"preferences";
static NSString * const kActionImportDict = @"importDict";
static NSString * const kActionQuit = @"quit";

@implementation StatusBarItem

- (instancetype)initWithServer:(IMKServer *)server {
    self = [super init];
    if (self) {
        _server = server;
    }
    return self;
}

- (void)setupStatusBar {
    // 创建状态栏�?
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    // 设置按钮
    NSStatusBarButton *button = _statusItem.button;
    button.title = @"�?;  // 中文模式标识
    button.toolTip = @"西蒙输入�?- 中文模式";
    button.action = @selector(statusBarClicked:);
    button.target = self;
    
    // 设置菜单
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"西蒙输入�?];
    
    // 当前模式显示
    NSMenuItem *modeItem = [[NSMenuItem alloc] initWithTitle:@"当前模式：中�?
                                                      action:nil
                                               keyEquivalent:@""];
    modeItem.tag = 100;
    modeItem.enabled = NO;
    [menu addItem:modeItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 切换中英�?
    NSMenuItem *toggleItem = [[NSMenuItem alloc] initWithTitle:@"切换到英文模�?
                                                        action:@selector(toggleInputMode:)
                                                 keyEquivalent:@""];
    toggleItem.target = self;
    [menu addItem:toggleItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 导入搜狗词库
    NSMenuItem *importItem = [[NSMenuItem alloc] initWithTitle:@"导入搜狗词库..."
                                                        action:@selector(importSogouDictionary:)
                                                 keyEquivalent:@""];
    importItem.target = self;
    [menu addItem:importItem];
    
    // 偏好设置
    NSMenuItem *prefItem = [[NSMenuItem alloc] initWithTitle:@"偏好设置..."
                                                      action:@selector(showPreferences:)
                                               keyEquivalent:@","];
    prefItem.target = self;
    [menu addItem:prefItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 关于
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"关于西蒙输入�?
                                                       action:@selector(showAbout:)
                                                keyEquivalent:@""];
    aboutItem.target = self;
    [menu addItem:aboutItem];
    
    // 退�?
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出西蒙输入法"
                                                      action:@selector(quitInputMethod:)
                                               keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    
    _statusItem.menu = menu;
    
    NSLog(@"[StatusBarItem] 状态栏已设�?);
}

- (void)updateStatusIcon {
    if (!_statusItem) return;
    
    InputController *controller = [InputController currentController];
    InputMode mode = controller.inputMode;
    
    NSStatusBarButton *button = _statusItem.button;
    
    switch (mode) {
        case InputModeChinese:
            button.title = @"�?;
            button.toolTip = @"西蒙输入�?- 中文模式";
            break;
        case InputModeEnglish:
            button.title = @"En";
            button.toolTip = @"西蒙输入�?- 英文模式";
            break;
        case InputModeFullWidth:
            button.title = @"�?;
            button.toolTip = @"西蒙输入�?- 全角模式";
            break;
    }
    
    // 更新菜单中的模式显示
    NSMenu *menu = _statusItem.menu;
    NSMenuItem *modeItem = [menu itemWithTag:100];
    if (modeItem) {
        NSString *modeName;
        switch (mode) {
            case InputModeChinese: modeName = @"中文"; break;
            case InputModeEnglish: modeName = @"英文"; break;
            case InputModeFullWidth: modeName = @"全角"; break;
            default: modeName = @"未知"; break;
        }
        modeItem.title = [NSString stringWithFormat:@"当前模式�?@", modeName];
    }
    
    // 更新切换菜单项文�?
    NSMenuItem *toggleItem = [menu itemAtIndex:3]; // 切换模式�?
    if (toggleItem) {
        toggleItem.title = (mode == InputModeChinese) ? @"切换到英文模�? : @"切换到中文模�?;
    }
}

- (void)tearDown {
    if (_statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
        _statusItem = nil;
    }
}

#pragma mark - 菜单动作

- (void)statusBarClicked:(id)sender {
    // 点击状态栏图标时切换模�?
    [self toggleInputMode:sender];
}

- (void)toggleInputMode:(id)sender {
    InputController *controller = [InputController currentController];
    [controller toggleInputMode];
    [self updateStatusIcon];
}

- (void)showPreferences:(id)sender {
    // 打开偏好设置窗口
    NSWindowController *prefWC = [[NSWindowController alloc] 
        initWithWindowNibName:@"PreferencesWindow"];
    [prefWC showWindow:nil];
}

- (void)importSogouDictionary:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.data"]];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.title = @"选择搜狗词库文件 (.scel)";
    openPanel.message = @"请选择要导入的搜狗词库文件";
    
    [openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = openPanel.URLs.firstObject;
            if (fileURL) {
                [self performImportWithFileURL:fileURL];
            }
        }
    }];
}

- (void)performImportWithFileURL:(NSURL *)fileURL {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"正在导入词库...";
    alert.informativeText = [NSString stringWithFormat:@"正在导入: %@", fileURL.lastPathComponent];
    alert.alertStyle = NSAlertStyleInformational;
    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
    
    // 异步导入
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO: 调用 DictionaryManager 的导入方�?
        NSLog(@"[StatusBarItem] 开始导入词�? %@", fileURL.path);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert.window close];
            
            NSAlert *doneAlert = [[NSAlert alloc] init];
            doneAlert.messageText = @"词库导入完成";
            doneAlert.informativeText = @"搜狗词库已成功导�?;
            doneAlert.alertStyle = NSAlertStyleInformational;
            [doneAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
        });
    });
}

- (void)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"西蒙输入�?v1.0.0";
    alert.informativeText = @"一款支持搜狗词库导入的 macOS 拼音输入法\n\n"
                           @"功能特点：\n"
                           @"�?智能拼音输入\n"
                           @"�?搜狗 .scel 词库导入\n"
                           @"�?模糊音支持\n"
                           @"�?用户词频自适应\n"
                           @"�?自定义短语\n\n"
                           @"兼容 macOS 11.0 (Big Sur) 及以�?;
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}

- (void)quitInputMethod:(id)sender {
    [NSApp terminate:self];
}

@end
