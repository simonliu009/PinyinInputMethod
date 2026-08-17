/*
 * PinyinInputMethod - macOS 拼音输入法
 * InstallationGuide.m - 安装引导界面实现
 */

#import "InstallationGuide.h"

static NSString * const kGuideCompletedKey = @"installationGuideCompleted";

@implementation InstallationGuide {
    NSInteger _currentStep;
    NSView *_contentContainer;
}

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 560, 420)
                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                    backing:NSBackingStoreBuffered
                      defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        [window setTitle:@"拼音输入法 - 安装引导"];
        [window center];
        [window setStyleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable];
        _currentStep = 0;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self buildUI];
    [self showStep:0];
}

+ (BOOL)shouldShowGuide {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kGuideCompletedKey];
}

+ (void)markGuideCompleted {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGuideCompletedKey];
}

#pragma mark - 界面构建

- (void)buildUI {
    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    
    // 标题
    NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(30, 360, 500, 30)];
    title.stringValue = @"欢迎使用拼音输入法";
    title.font = [NSFont boldSystemFontOfSize:22];
    title.editable = NO;
    title.bordered = NO;
    title.backgroundColor = [NSColor clearColor];
    [contentView addSubview:title];
    
    // 内容容器
    _contentContainer = [[NSView alloc] initWithFrame:NSMakeRect(30, 80, 500, 260)];
    [contentView addSubview:_contentContainer];
    
    // 底部按钮区
    NSButton *prevBtn = [[NSButton alloc] initWithFrame:NSMakeRect(30, 30, 80, 32)];
    prevBtn.title = @"上一步";
    prevBtn.bezelStyle = NSBezelStyleRounded;
    prevBtn.action = @selector(previousStep:);
    prevBtn.target = self;
    prevBtn.tag = 201;
    [contentView addSubview:prevBtn];
    
    NSButton *nextBtn = [[NSButton alloc] initWithFrame:NSMakeRect(450, 30, 80, 32)];
    nextBtn.title = @"下一步";
    nextBtn.bezelStyle = NSBezelStyleRounded;
    nextBtn.action = @selector(nextStep:);
    nextBtn.target = self;
    nextBtn.tag = 202;
    [contentView addSubview:nextBtn];
    
    // 步骤指示器
    NSTextField *stepIndicator = [[NSTextField alloc] initWithFrame:NSMakeRect(230, 38, 100, 20)];
    stepIndicator.editable = NO;
    stepIndicator.bordered = NO;
    stepIndicator.backgroundColor = [NSColor clearColor];
    stepIndicator.alignment = NSTextAlignmentCenter;
    stepIndicator.font = [NSFont systemFontOfSize:12];
    stepIndicator.textColor = [NSColor secondaryLabelColor];
    stepIndicator.tag = 203;
    [contentView addSubview:stepIndicator];
}

#pragma mark - 步骤管理

- (void)showStep:(NSInteger)step {
    _currentStep = step;
    
    // 清空内容容器
    for (NSView *subview in _contentContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    // 更新步骤指示器
    NSTextField *indicator = [_contentContainer.window.contentView viewWithTag:203];
    indicator.stringValue = [NSString stringWithFormat:@"步骤 %ld / 3", (long)(step + 1)];
    
    // 更新按钮状态
    NSButton *prevBtn = [_contentContainer.window.contentView viewWithTag:201];
    NSButton *nextBtn = [_contentContainer.window.contentView viewWithTag:202];
    
    prevBtn.enabled = (step > 0);
    
    switch (step) {
        case 0:
            [self buildStep1Welcome];
            nextBtn.title = @"下一步";
            break;
        case 1:
            [self buildStep2Enable];
            nextBtn.title = @"下一步";
            break;
        case 2:
            [self buildStep3Customize];
            nextBtn.title = @"完成";
            break;
    }
}

#pragma mark - 步骤 1：欢迎

- (void)buildStep1Welcome {
    NSTextField *desc = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 180, 500, 60)];
    desc.stringValue = @"感谢安装拼音输入法！\n本引导将帮助您完成初始配置。";
    desc.font = [NSFont systemFontOfSize:14];
    desc.editable = NO;
    desc.bordered = NO;
    desc.backgroundColor = [NSColor clearColor];
    desc.maximumNumberOfLines = 3;
    [_contentContainer addSubview:desc];
    
    // 功能列表
    NSArray *features = @[
        @"• 智能拼音输入，支持词组联想",
        @"• 导入搜狗输入法词库（.scel 格式）",
        @"• 模糊音支持（z/zh, c/ch, s/sh 等）",
        @"• 用户词频自适应学习",
        @"• 自定义短语（日期、时间等）",
    ];
    
    CGFloat y = 140;
    for (NSString *feature in features) {
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, y, 460, 20)];
        label.stringValue = feature;
        label.font = [NSFont systemFontOfSize:13];
        label.editable = NO;
        label.bordered = NO;
        label.backgroundColor = [NSColor clearColor];
        [_contentContainer addSubview:label];
        y -= 25;
    }
}

#pragma mark - 步骤 2：启用输入法

- (void)buildStep2Enable {
    NSTextField *desc = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 210, 500, 40)];
    desc.stringValue = @"请在系统设置中启用本输入法：";
    desc.font = [NSFont systemFontOfSize:14];
    desc.editable = NO;
    desc.bordered = NO;
    desc.backgroundColor = [NSColor clearColor];
    [_contentContainer addSubview:desc];
    
    // 步骤说明
    NSArray *steps = @[
        @"1. 打开「系统偏好设置」→「键盘」→「输入法」",
        @"2. 点击左下角的「+」按钮",
        @"3. 在列表中找到「拼音输入法」",
        @"4. 点击「添加」按钮",
        @"5. 确保勾选了「在菜单栏中显示输入法菜单」",
    ];
    
    CGFloat y = 170;
    for (NSString *step in steps) {
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, y, 460, 22)];
        label.stringValue = step;
        label.font = [NSFont systemFontOfSize:13];
        label.editable = NO;
        label.bordered = NO;
        label.backgroundColor = [NSColor clearColor];
        [_contentContainer addSubview:label];
        y -= 28;
    }
    
    // 打开系统设置按钮
    NSButton *openSettingsBtn = [[NSButton alloc] initWithFrame:NSMakeRect(20, 10, 200, 32)];
    openSettingsBtn.title = @"打开系统偏好设置...";
    openSettingsBtn.bezelStyle = NSBezelStyleRounded;
    openSettingsBtn.action = @selector(openSystemPreferences:);
    openSettingsBtn.target = self;
    [_contentContainer addSubview:openSettingsBtn];
}

#pragma mark - 步骤 3：个性化设置

- (void)buildStep3Customize {
    NSTextField *desc = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 210, 500, 40)];
    desc.stringValue = @"您可以根据需要调整以下设置（稍后也可在偏好设置中修改）：";
    desc.font = [NSFont systemFontOfSize:14];
    desc.editable = NO;
    desc.bordered = NO;
    desc.backgroundColor = [NSColor clearColor];
    desc.maximumNumberOfLines = 2;
    [_contentContainer addSubview:desc];
    
    // 模糊音选项
    NSTextField *fuzzyTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 170, 200, 20)];
    fuzzyTitle.stringValue = @"模糊音设置（可选）：";
    fuzzyTitle.font = [NSFont boldSystemFontOfSize:13];
    fuzzyTitle.editable = NO;
    fuzzyTitle.bordered = NO;
    fuzzyTitle.backgroundColor = [NSColor clearColor];
    [_contentContainer addSubview:fuzzyTitle];
    
    NSArray *fuzzyOptions = @[@"z/zh", @"c/ch", @"s/sh", @"n/l", @"f/h"];
    CGFloat y = 140;
    for (NSInteger i = 0; i < (NSInteger)fuzzyOptions.count; i++) {
        NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(20 + (i % 3) * 150, y, 120, 20)];
        checkbox.title = fuzzyOptions[i];
        checkbox.buttonType = NSButtonTypeSwitch;
        checkbox.tag = 300 + i;
        [_contentContainer addSubview:checkbox];
        if (i % 3 == 2) y -= 30;
    }
    
    // 导入词库提示
    NSTextField *dictHint = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 40, 480, 40)];
    dictHint.stringValue = @"提示：您可以随时通过菜单栏的输入法图标\n导入搜狗输入法的 .scel 词库文件来扩展词汇量。";
    dictHint.font = [NSFont systemFontOfSize:12];
    dictHint.textColor = [NSColor secondaryLabelColor];
    dictHint.editable = NO;
    dictHint.bordered = NO;
    dictHint.backgroundColor = [NSColor clearColor];
    dictHint.maximumNumberOfLines = 2;
    [_contentContainer addSubview:dictHint];
}

#pragma mark - 按钮动作

- (IBAction)previousStep:(id)sender {
    if (_currentStep > 0) {
        [self showStep:_currentStep - 1];
    }
}

- (IBAction)nextStep:(id)sender {
    if (_currentStep < 2) {
        [self showStep:_currentStep + 1];
    } else {
        // 最后一步：保存设置并完成
        [self saveGuideSettings];
        [InstallationGuide markGuideCompleted];
        [self.window close];
    }
}

- (IBAction)openSystemPreferences:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.keyboard"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)saveGuideSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 保存模糊音设置
    NSArray *fuzzyKeys = @[@"fuzzyZ_ZH", @"fuzzyC_CH", @"fuzzyS_SH", @"fuzzyN_L", @"fuzzyF_H"];
    for (NSInteger i = 0; i < (NSInteger)fuzzyKeys.count; i++) {
        NSButton *checkbox = [_contentContainer viewWithTag:300 + i];
        if (checkbox) {
            [defaults setBool:(checkbox.state == NSControlStateValueOn) forKey:fuzzyKeys[i]];
        }
    }
}

@end
