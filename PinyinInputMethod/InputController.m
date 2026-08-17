/*
 * PinyinInputMethod - macOS 拼音输入法
 * InputController.m - IMK 输入控制器实现
 *
 * 核心输入控制器，处理键盘事件、管理输入状态、协调拼音引擎和候选窗口
 */

#import "InputController.h"
#import "PinyinEngine.h"
#import "CandidateWindow.h"
#import "DictionaryManager.h"
#import "AppDelegate.h"
#import "StatusBarItem.h"
#import "ConfigManager.h"
#import <objc/message.h>

// 虚拟键码已由 Carbon.framework (Events.h) 提供，无需重复定义

static InputController *currentInstance = nil;

@implementation InputController

#pragma mark - 初始化

- (instancetype)initWithServer:(IMKServer *)server
                    client:(id)client
{
    self = [super init];
    if (self) {
        currentInstance = self;
        
        // 初始化状态
        _inputMode = InputModeChinese;
        _isComposing = NO;
        _currentPage = 0;
        _selectedCandidateIndex = 0;
        _candidatesPerPage = [[ConfigManager sharedManager] integerForKey:@"candidatesPerPage" defaultValue:5];
        
        // 初始化拼音字符串
        _currentPinyin = [NSMutableString stringWithCapacity:32];
        
        // 初始化拼音引擎
        _pinyinEngine = [[PinyinEngine alloc] init];
        
        // 获取词库管理器
        _dictionaryManager = [AppDelegate sharedAppDelegate].dictionaryManager;
        
        // 初始化候选窗口
        _candidateWindow = [[CandidateWindow alloc] init];
        
        NSLog(@"[InputController] 控制器已初始化");
    }
    return self;
}

+ (instancetype)currentController {
    return currentInstance;
}

#pragma mark - 服务器生命周期

- (void)activateServer:(NSNotification *)notification {
    NSLog(@"[InputController] 输入法已激活");
    
    // 从配置中恢复输入模式
    NSInteger savedMode = [[ConfigManager sharedManager] integerForKey:@"inputMode" 
                                                       defaultValue:InputModeChinese];
    _inputMode = (InputMode)savedMode;
}

- (void)deactivateServer:(NSNotification *)notification {
    NSLog(@"[InputController] 输入法已停用");
    
    // 如果有正在组合的输入，先提交
    if (_isComposing) {
        [self commitComposition:nil];
        [self resetComposition];
    }
    
    // 隐藏候选窗口
    [_candidateWindow orderOut:nil];
}

#pragma mark - 键盘事件处理

- (BOOL)inputText:(NSString *)inputString 
              key:(NSInteger)keyCode 
        modifiers:(NSEventModifierFlags)flags
{
    // 忽略修饰键单独按下
    if (flags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption)) {
        return NO;  // 让系统处理
    }
    
    // Shift 键切换中英文模式
    if (keyCode == 56 || keyCode == 60) {  // Left/Right Shift
        if (!(flags & NSEventModifierFlagShift)) {
            // Shift 释放时切换
            [self toggleInputMode];
            return YES;
        }
        return NO;
    }
    
    // 根据当前模式分发处理
    switch (_inputMode) {
        case InputModeEnglish:
            return [self handleEnglishInput:inputString keyCode:keyCode modifiers:flags];
        case InputModeChinese:
            return [self handleChineseInput:inputString keyCode:keyCode modifiers:flags];
        case InputModeFullWidth:
            return [self handleFullWidthInput:inputString keyCode:keyCode modifiers:flags];
        default:
            return NO;
    }
}

#pragma mark - 英文模式处理

- (BOOL)handleEnglishInput:(NSString *)inputString 
                   keyCode:(NSInteger)keyCode 
                 modifiers:(NSEventModifierFlags)flags
{
    // 英文模式下直接传递字符
    if (inputString.length > 0 && keyCode < 128) {
        [self commitText:inputString];
        return YES;
    }
    return NO;
}

#pragma mark - 中文模式处理

- (BOOL)handleChineseInput:(NSString *)inputString 
                   keyCode:(NSInteger)keyCode 
                 modifiers:(NSEventModifierFlags)flags
{
    // 处理特殊按键
    switch (keyCode) {
        case kVK_Escape:
            return [self handleEscape];
        case kVK_Return:
            return [self handleReturn];
        case kVK_Space:
            return [self handleSpace];
        case kVK_Delete:
            return [self handleBackspace];
        case kVK_ForwardDelete:
            return [self handleForwardDelete];
    }
    
    // 处理翻页键
    if (keyCode == 0x21) {  // Page Up / [ 键（部分键盘）
        return [self handlePageUp];
    }
    if (keyCode == 0x1E) {  // Page Down / ] 键
        return [self handlePageDown];
    }
    
    // 处理数字键选词（1-9）
    if (_isComposing && keyCode >= 0x12 && keyCode <= 0x1A) {
        NSInteger index = keyCode - 0x12;  // 1->0, 2->1, ..., 9->8
        return [self handleCandidateSelection:index];
    }
    
    // 处理字母输入
    if (inputString.length > 0) {
        unichar ch = [inputString characterAtIndex:0];
        
        // 只处理小写字母
        if (ch >= 'a' && ch <= 'z') {
            [_currentPinyin appendString:inputString];
            _isComposing = YES;
            _currentPage = 0;
            _selectedCandidateIndex = 0;
            [self updateCandidates];
            return YES;
        }
        
        // 处理标点符号
        if ([self isPunctuation:ch]) {
            if (_isComposing) {
                [self commitComposition:nil];
                [self resetComposition];
            }
            NSString *punct = [self convertPunctuation:ch];
            [self commitText:punct];
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - 全角模式处理

- (BOOL)handleFullWidthInput:(NSString *)inputString 
                     keyCode:(NSInteger)keyCode 
                   modifiers:(NSEventModifierFlags)flags
{
    if (inputString.length > 0 && keyCode < 128) {
        // 转换为全角字符
        NSString *fullWidth = [self convertToFullWidth:inputString];
        [self commitText:fullWidth];
        return YES;
    }
    return NO;
}

#pragma mark - 特殊按键处理

- (BOOL)handleEscape {
    if (_isComposing) {
        [self resetComposition];
        [self hideCandidateWindow];
        return YES;
    }
    return NO;
}

- (BOOL)handleReturn {
    if (_isComposing) {
        // 回车时直接提交拼音原文
        [self commitText:[_currentPinyin copy]];
        [self resetComposition];
        [self hideCandidateWindow];
        return YES;
    }
    return NO;
}

- (BOOL)handleSpace {
    if (_isComposing) {
        if (_currentPageCandidates.count > 0) {
            // 提交当前选中的候选词
            NSString *selected;
            if (_selectedCandidateIndex < (NSInteger)_currentPageCandidates.count) {
                selected = _currentPageCandidates[_selectedCandidateIndex];
            } else {
                selected = _currentPageCandidates.firstObject;
            }
            [self commitText:selected];
            
            // 记录用户选择（用于词频学习）
            [_pinyinEngine recordUserSelection:[_currentPinyin copy] word:selected];
            
            [self resetComposition];
            [self hideCandidateWindow];
        } else {
            // 没有候选词，提交拼音
            [self commitText:[_currentPinyin copy]];
            [self resetComposition];
        }
        return YES;
    }
    return NO;
}

- (BOOL)handleBackspace {
    if (_isComposing) {
        if (_currentPinyin.length > 0) {
            [_currentPinyin deleteCharactersInRange:NSMakeRange(_currentPinyin.length - 1, 1)];
            
            if (_currentPinyin.length == 0) {
                [self resetComposition];
                [self hideCandidateWindow];
            } else {
                _currentPage = 0;
                _selectedCandidateIndex = 0;
                [self updateCandidates];
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL)handleForwardDelete {
    // Forward delete 与 backspace 类似，但删除后面的字符
    // 简化处理：与 backspace 相同
    return [self handleBackspace];
}

#pragma mark - 候选词导航

- (BOOL)handlePageUp {
    if (_isComposing && _currentPage > 0) {
        _currentPage--;
        _selectedCandidateIndex = 0;
        [self updateCurrentPageCandidates];
        return YES;
    }
    return NO;
}

- (BOOL)handlePageDown {
    if (_isComposing) {
        _currentPage++;
        _selectedCandidateIndex = 0;
        [self updateCurrentPageCandidates];
        return YES;
    }
    return NO;
}

- (BOOL)handleCandidateSelection:(NSInteger)index {
    if (_isComposing && index < (NSInteger)_currentPageCandidates.count) {
        NSString *selected = _currentPageCandidates[index];
        [self commitText:selected];
        
        // 记录用户选择
        [_pinyinEngine recordUserSelection:[_currentPinyin copy] word:selected];
        
        [self resetComposition];
        [self hideCandidateWindow];
        return YES;
    }
    return NO;
}

#pragma mark - 候选词更新

- (void)updateCandidates {
    if (_currentPinyin.length == 0) {
        [self hideCandidateWindow];
        return;
    }
    
    // 从拼音引擎获取候选词
    NSArray *candidates = [_pinyinEngine getCandidatesForPinyin:_currentPinyin
                                               dictionaryManager:_dictionaryManager];
    
    // 更新当前页候选词
    _currentPageCandidates = [self candidatesForPage:_currentPage fromAll:candidates];
    
    // 更新候选窗口显示
    if (_currentPageCandidates.count > 0) {
        [self showCandidateWindow];
    } else {
        [self hideCandidateWindow];
    }
    
    // 更新预编辑文本（显示拼音和选中下划线）
    [self updatePreeditText];
}

- (void)updateCurrentPageCandidates {
    // 重新获取所有候选词并翻页
    NSArray *allCandidates = [_pinyinEngine getCandidatesForPinyin:_currentPinyin
                                                  dictionaryManager:_dictionaryManager];
    _currentPageCandidates = [self candidatesForPage:_currentPage fromAll:allCandidates];
    
    if (_currentPageCandidates.count > 0) {
        [self showCandidateWindow];
    } else {
        // 没有更多页，回退
        _currentPage = MAX(0, _currentPage - 1);
        _currentPageCandidates = [self candidatesForPage:_currentPage fromAll:allCandidates];
        if (_currentPageCandidates.count > 0) {
            [self showCandidateWindow];
        } else {
            [self hideCandidateWindow];
        }
    }
}

- (NSArray *)candidatesForPage:(NSInteger)page fromAll:(NSArray *)allCandidates {
    NSInteger start = page * _candidatesPerPage;
    if (start >= (NSInteger)allCandidates.count) {
        return @[];
    }
    
    NSInteger end = MIN(start + _candidatesPerPage, (NSInteger)allCandidates.count);
    return [allCandidates subarrayWithRange:NSMakeRange(start, end - start)];
}

#pragma mark - 预编辑文本

- (void)updatePreeditText {
    if (!_isComposing) return;
    
    id client = [self client];
    
    // 设置高亮属性
    NSDictionary *attrs = @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSFontAttributeName: [NSFont systemFontOfSize:14]
    };
    
    // 显示拼音 + 第一个候选词
    NSString *displayText;
    if (_currentPageCandidates.count > 0) {
        displayText = _currentPageCandidates.firstObject;
    } else {
        displayText = [_currentPinyin copy];
    }
    
    // 标记组合文本
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:displayText
                                                                  attributes:attrs];
    
    [client setMarkedText:attrStr 
        selectionRange:NSMakeRange(displayText.length, 0) 
         replacementRange:NSMakeRange(0, 0)];
}

#pragma mark - 文本提交

- (void)commitText:(NSString *)text {
    if (!text || text.length == 0) return;
    
    id client = [self client];
    [client insertText:text replacementRange:NSMakeRange(0, 0)];
}

- (void)commitComposition:(id)sender {
    if (_isComposing && _currentPinyin.length > 0) {
        if (_currentPageCandidates.count > 0 && _selectedCandidateIndex < (NSInteger)_currentPageCandidates.count) {
            [self commitText:_currentPageCandidates[_selectedCandidateIndex]];
        } else {
            [self commitText:[_currentPinyin copy]];
        }
    }
}

#pragma mark - 状态管理

- (void)resetComposition {
    [_currentPinyin setString:@""];
    _isComposing = NO;
    _currentPage = 0;
    _selectedCandidateIndex = 0;
    _currentPageCandidates = @[];
}

- (void)toggleInputMode {
    switch (_inputMode) {
        case InputModeChinese:
            _inputMode = InputModeEnglish;
            break;
        case InputModeEnglish:
            _inputMode = InputModeChinese;
            break;
        case InputModeFullWidth:
            _inputMode = InputModeChinese;
            break;
    }
    
    // 保存模式
    [[ConfigManager sharedManager] setInteger:_inputMode forKey:@"inputMode"];
    
    // 更新状态栏图标
    AppDelegate *app = (AppDelegate *)[AppDelegate sharedAppDelegate];
    [app.statusBarItem updateStatusIcon];
    
    // 如果切换模式时有组合输入，提交它
    if (_isComposing) {
        [self commitText:[_currentPinyin copy]];
        [self resetComposition];
        [self hideCandidateWindow];
    }
    
    NSLog(@"[InputController] 输入模式切换为: %ld", (long)_inputMode);
}

#pragma mark - 候选窗口管理

- (void)showCandidateWindow {
    if (_currentPageCandidates.count == 0) {
        [self hideCandidateWindow];
        return;
    }
    
    // 获取光标位置
    NSRect cursorRect = [self cursorRectForClient];
    
    // 构建候选词显示文本
    NSMutableArray *displayCandidates = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)_currentPageCandidates.count; i++) {
        NSString *num = [NSString stringWithFormat:@"%ld.", (long)(i + 1)];
        NSString *word = _currentPageCandidates[i];
        [displayCandidates addObject:[NSString stringWithFormat:@"%@ %@", num, word]];
    }
    
    [_candidateWindow showWithCandidates:displayCandidates
                            atPosition:cursorRect.origin
                            client:[self client]];
}

- (void)hideCandidateWindow {
    [_candidateWindow orderOut:nil];
}

- (NSRect)cursorRectForClient {
    id client = [self client];
    
    // 通过 IMK 获取光标位置
    id textInput = [self client];
    NSDictionary *attrs = nil;
    SEL sel = @selector(attributesForCharacterIndex:lineHeightRectangleInstead:);
    if ([textInput respondsToSelector:sel]) {
        NSDictionary *(*msgSend)(id, SEL, NSInteger, BOOL) = (void *)objc_msgSend;
        attrs = msgSend(textInput, sel, 0, YES);
    }
    if (attrs) {
        NSValue *rectValue = attrs[@"kIMKTextFrame"];
        if (rectValue) {
            return [rectValue rectValue];
        }
    }
    
    // 默认位置
    return NSMakeRect(100, 100, 0, 0);
}

#pragma mark - 辅助方法

- (BOOL)isPunctuation:(unichar)ch {
    static NSCharacterSet *punctSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        punctSet = [NSCharacterSet characterSetWithCharactersInString:
            @".,;:!?()[]{}@#$%^&*_+-=|\\/~`'\"<>"];
    });
    return [punctSet characterIsMember:ch];
}

- (NSString *)convertPunctuation:(unichar)ch {
    // 半角标点转全角
    static NSDictionary *punctMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        punctMap = @{
            @",": @"，",
            @".": @"。",
            @"!": @"！",
            @"?": @"？",
            @";": @"；",
            @":": @"：",
            @"(": @"（",
            @")": @"）",
            @"[": @"【",
            @"]": @"】",
            @"<": @"《",
            @">": @"》",
        };
    });
    
    NSString *key = [NSString stringWithFormat:@"%C", ch];
    NSString *mapped = punctMap[key];
    return mapped ?: key;
}

- (NSString *)convertToFullWidth:(NSString *)text {
    NSMutableString *result = [NSMutableString stringWithCapacity:text.length];
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar ch = [text characterAtIndex:i];
        if (ch >= 0x21 && ch <= 0x7E) {
            // ASCII 可见字符转全角
            [result appendFormat:@"%C", (unichar)(ch + 0xFEE0)];
        } else if (ch == 0x20) {
            // 空格转全角空格
            [result appendFormat:@"%C", (unichar)0x3000];
        } else {
            [result appendFormat:@"%C", ch];
        }
    }
    return result;
}

#pragma mark - IMK 状态查询

- (NSArray *)validAttributesForMarkedText {
    return @[
        NSForegroundColorAttributeName,
        NSBackgroundColorAttributeName,
        NSUnderlineStyleAttributeName,
        NSUnderlineColorAttributeName,
    ];
}

- (void)mouseDownOnCharacterIndex:(NSInteger)index {
    // 点击候选词窗口中的候选词
    if (_isComposing && index < (NSInteger)_currentPageCandidates.count) {
        NSString *selected = _currentPageCandidates[index];
        [self commitText:selected];
        [_pinyinEngine recordUserSelection:[_currentPinyin copy] word:selected];
        [self resetComposition];
        [self hideCandidateWindow];
    }
}

@end
