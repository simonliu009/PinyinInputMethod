/*
 * PinyinInputMethod - macOS 西蒙输入�?
 * PreferencesWindow.m - 偏好设置窗口实现
 *
 * 使用代码动态构建界面（无需 xib�?
 */

#import "PreferencesWindow.h"
#import "ConfigManager.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation PreferencesWindow

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] 
        initWithContentRect:NSMakeRect(0, 0, 480, 380)
                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                    backing:NSBackingStoreBuffered
                      defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        [window setTitle:@"西蒙输入�?- 偏好设置"];
        [window center];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self buildUI];
    [self loadSettings];
}

#pragma mark - 界面构建

- (void)buildUI {
    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    // 创建标签�?
    NSTabView *tabView = [[NSTabView alloc] initWithFrame:contentView.bounds];
    tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _tabView = tabView;
    
    // 基本设置标签�?
    NSTabViewItem *basicTab = [[NSTabViewItem alloc] initWithIdentifier:@"basic"];
    basicTab.label = @"基本设置";
    [basicTab setView:[self buildBasicSettingsView]];
    [tabView addTabViewItem:basicTab];
    
    // 模糊音标签页
    NSTabViewItem *fuzzyTab = [[NSTabViewItem alloc] initWithIdentifier:@"fuzzy"];
    fuzzyTab.label = @"模糊�?;
    [fuzzyTab setView:[self buildFuzzySettingsView]];
    [tabView addTabViewItem:fuzzyTab];
    
    // 词库管理标签�?
    NSTabViewItem *dictTab = [[NSTabViewItem alloc] initWithIdentifier:@"dict"];
    dictTab.label = @"词库管理";
    [dictTab setView:[self buildDictionaryView]];
    [tabView addTabViewItem:dictTab];
    
    // 自定义短语标签页
    NSTabViewItem *phraseTab = [[NSTabViewItem alloc] initWithIdentifier:@"phrase"];
    phraseTab.label = @"自定义短�?;
    [phraseTab setView:[self buildPhraseView]];
    [tabView addTabViewItem:phraseTab];
    
    [contentView addSubview:tabView];
}

#pragma mark - 基本设置

- (NSView *)buildBasicSettingsView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 440, 300)];
    CGFloat y = 260;
    
    // 候选词数量
    NSTextField *label1 = [self createLabel:@"每页候选词数量�? atY:y];
    [view addSubview:label1];
    
    NSPopUpButton *countPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(180, y - 2, 80, 26)];
    [countPopup addItemsWithTitles:@[@"5", @"6", @"7", @"8", @"9"]];
    countPopup.tag = 101;
    [view addSubview:countPopup];
    
    y -= 40;
    
    // 默认输入模式
    NSTextField *label2 = [self createLabel:@"默认输入模式�? atY:y];
    [view addSubview:label2];
    
    NSPopUpButton *modePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(180, y - 2, 120, 26)];
    [modePopup addItemsWithTitles:@[@"中文", @"英文"]];
    modePopup.tag = 102;
    [view addSubview:modePopup];
    
    y -= 40;
    
    // 中英文切换快捷键
    NSTextField *label3 = [self createLabel:@"中英文切换：" atY:y];
    [view addSubview:label3];
    
    NSPopUpButton *switchPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(180, y - 2, 120, 26)];
    [switchPopup addItemsWithTitles:@[@"Shift", @"Ctrl+Space", @"Command"]];
    switchPopup.tag = 103;
    [view addSubview:switchPopup];
    
    y -= 40;
    
    // 记住上次输入模式
    NSButton *rememberCheck = [[NSButton alloc] initWithFrame:NSMakeRect(180, y, 200, 20)];
    rememberCheck.title = @"记住上次的输入模�?;
    rememberCheck.bezelStyle = NSBezelStyleRounded;
    rememberCheck.buttonType = NSButtonTypeSwitch;
    rememberCheck.tag = 104;
    [view addSubview:rememberCheck];
    
    return view;
}

#pragma mark - 模糊音设�?

- (NSView *)buildFuzzySettingsView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 440, 300)];
    
    // 标题
    NSTextField *title = [self createLabel:@"选择需要启用的模糊音：" atY:270];
    title.font = [NSFont boldSystemFontOfSize:13];
    [view addSubview:title];
    
    CGFloat y = 240;
    CGFloat x1 = 40, x2 = 220;
    
    // 声母模糊
    NSArray *fuzzyPairs = @[
        @[@"z/zh", @"fuzzyZ_ZH"],
        @[@"c/ch", @"fuzzyC_CH"],
        @[@"s/sh", @"fuzzyS_SH"],
        @[@"n/l",  @"fuzzyN_L"],
        @[@"f/h",  @"fuzzyF_H"],
    ];
    
    for (NSInteger i = 0; i < (NSInteger)fuzzyPairs.count; i++) {
        NSArray *pair = fuzzyPairs[i];
        CGFloat x = (i % 2 == 0) ? x1 : x2;
        CGFloat currentY = y - (i / 2) * 35;
        
        NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(x, currentY, 150, 20)];
        checkbox.title = pair[0];
        checkbox.bezelStyle = NSBezelStyleRounded;
        checkbox.buttonType = NSButtonTypeSwitch;
        checkbox.tag = 200 + i;
        [view addSubview:checkbox];
    }
    
    y -= 120;
    
    // 韵母模糊
    NSTextField *rimeTitle = [self createLabel:@"韵母模糊�? atY:y];
    rimeTitle.font = [NSFont boldSystemFontOfSize:13];
    [view addSubview:rimeTitle];
    
    y -= 30;
    
    NSArray *rimePairs = @[
        @[@"an/ang", @"fuzzyAn_Ang"],
        @[@"en/eng", @"fuzzyEn_Eng"],
        @[@"in/ing", @"fuzzyIn_In"],
    ];
    
    for (NSInteger i = 0; i < (NSInteger)rimePairs.count; i++) {
        NSArray *pair = rimePairs[i];
        CGFloat x = (i % 2 == 0) ? x1 : x2;
        CGFloat currentY = y - (i / 2) * 35;
        
        NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(x, currentY, 150, 20)];
        checkbox.title = pair[0];
        checkbox.bezelStyle = NSBezelStyleRounded;
        checkbox.buttonType = NSButtonTypeSwitch;
        checkbox.tag = 210 + i;
        [view addSubview:checkbox];
    }
    
    return view;
}

#pragma mark - 词库管理

- (NSView *)buildDictionaryView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 440, 300)];
    CGFloat y = 260;
    
    // 词库信息
    NSTextField *infoLabel = [self createLabel:@"词库信息" atY:y];
    infoLabel.font = [NSFont boldSystemFontOfSize:13];
    [view addSubview:infoLabel];
    
    y -= 30;
    NSTextField *countLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, y, 360, 20)];
    countLabel.stringValue = @"词条总数：加载中...";
    countLabel.editable = NO;
    countLabel.bordered = NO;
    countLabel.backgroundColor = [NSColor clearColor];
    countLabel.tag = 301;
    [view addSubview:countLabel];
    
    y -= 40;
    
    // 导入按钮
    NSButton *importBtn = [[NSButton alloc] initWithFrame:NSMakeRect(40, y, 160, 32)];
    importBtn.title = @"导入搜狗词库 (.scel)";
    importBtn.bezelStyle = NSBezelStyleRounded;
    importBtn.action = @selector(importSogouDict:);
    importBtn.target = self;
    [view addSubview:importBtn];
    
    // 导出按钮
    NSButton *exportBtn = [[NSButton alloc] initWithFrame:NSMakeRect(220, y, 120, 32)];
    exportBtn.title = @"导出词库";
    exportBtn.bezelStyle = NSBezelStyleRounded;
    exportBtn.action = @selector(exportDictionary:);
    exportBtn.target = self;
    [view addSubview:exportBtn];
    
    y -= 50;
    
    // 清空按钮
    NSButton *clearBtn = [[NSButton alloc] initWithFrame:NSMakeRect(40, y, 160, 32)];
    clearBtn.title = @"清空搜狗词库";
    clearBtn.bezelStyle = NSBezelStyleRounded;
    clearBtn.action = @selector(clearSogouDict:);
    clearBtn.target = self;
    [view addSubview:clearBtn];
    
    return view;
}

#pragma mark - 自定义短�?

- (NSView *)buildPhraseView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 440, 300)];
    CGFloat y = 260;
    
    NSTextField *infoLabel = [self createLabel:@"自定义短语（输入触发键自动展开�? atY:y];
    infoLabel.font = [NSFont boldSystemFontOfSize:13];
    [view addSubview:infoLabel];
    
    y -= 30;
    
    // 示例说明
    NSTextField *descLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, y - 20, 360, 40)];
    descLabel.stringValue = @"格式：触发键 = 展开内容\n"
                           @"支持变量�?DATE(日期) $TIME(时间) $WEEKDAY(星期)";
    descLabel.editable = NO;
    descLabel.bordered = NO;
    descLabel.backgroundColor = [NSColor clearColor];
    descLabel.font = [NSFont systemFontOfSize:11];
    descLabel.textColor = [NSColor secondaryLabelColor];
    [view addSubview:descLabel];
    
    y -= 80;
    
    // 短语列表（简化为文本编辑�?
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(40, 40, 360, y - 40)];
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    
    NSTextView *textView = [[NSTextView alloc] initWithFrame:scrollView.contentView.bounds];
    textView.editable = YES;
    textView.selectable = YES;
    textView.richText = NO;
    textView.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
    textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    textView.identifier = @"customTextView";
    
    [scrollView setDocumentView:textView];
    [view addSubview:scrollView];
    
    return view;
}

#pragma mark - 设置加载/保存

- (void)loadSettings {
    ConfigManager *config = [ConfigManager sharedManager];
    
    // 基本设置
    NSPopUpButton *countPopup = [_tabView viewWithTag:101];
    NSInteger count = [config integerForKey:@"candidatesPerPage" defaultValue:5];
    [countPopup selectItemAtIndex:count - 5];
    
    // 模糊�?
    NSArray *fuzzyKeys = @[@"fuzzyZ_ZH", @"fuzzyC_CH", @"fuzzyS_SH", @"fuzzyN_L", @"fuzzyF_H"];
    for (NSInteger i = 0; i < (NSInteger)fuzzyKeys.count; i++) {
        NSButton *checkbox = [_tabView viewWithTag:200 + i];
        BOOL enabled = [config boolForKey:fuzzyKeys[i] defaultValue:NO];
        checkbox.state = enabled ? NSControlStateValueOn : NSControlStateValueOff;
    }
}

- (void)saveSettings {
    ConfigManager *config = [ConfigManager sharedManager];
    
    // 基本设置
    NSPopUpButton *countPopup = [_tabView viewWithTag:101];
    [config setInteger:countPopup.indexOfSelectedItem + 5 forKey:@"candidatesPerPage"];
    
    // 模糊�?
    NSArray *fuzzyKeys = @[@"fuzzyZ_ZH", @"fuzzyC_CH", @"fuzzyS_SH", @"fuzzyN_L", @"fuzzyF_H"];
    for (NSInteger i = 0; i < (NSInteger)fuzzyKeys.count; i++) {
        NSButton *checkbox = [_tabView viewWithTag:200 + i];
        [config setBool:(checkbox.state == NSControlStateValueOn) forKey:fuzzyKeys[i]];
    }
    
    [config saveConfig];
}

#pragma mark - 动作

- (IBAction)importSogouDict:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.data"]];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.title = @"选择搜狗词库文件";
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSLog(@"[Preferences] 导入词库: %@", panel.URL);
        }
    }];
}

- (IBAction)exportDictionary:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.plain-text"]];
    panel.nameFieldStringValue = @"pinyin_dictionary.txt";
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSLog(@"[Preferences] 导出词库�? %@", panel.URL);
        }
    }];
}

- (IBAction)clearSogouDict:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"确认清空";
    alert.informativeText = @"确定要清空所有搜狗导入的词库吗？此操作不可撤销�?;
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"清空"];
    [alert addButtonWithTitle:@"取消"];
    
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSAlertFirstButtonReturn) {
            NSLog(@"[Preferences] 清空搜狗词库");
        }
    }];
}

#pragma mark - 辅助

- (NSTextField *)createLabel:(NSString *)text atY:(CGFloat)y {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(40, y, 200, 20)];
    label.stringValue = text;
    label.editable = NO;
    label.bordered = NO;
    label.backgroundColor = [NSColor clearColor];
    return label;
}

- (void)windowWillClose:(NSNotification *)notification {
    [self saveSettings];
}

@end
