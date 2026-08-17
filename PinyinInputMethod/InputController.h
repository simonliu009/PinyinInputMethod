/*
 * PinyinInputMethod - macOS 拼音输入�?
 * InputController.h - IMK 输入控制器头文件
 *
 * 核心输入控制器，负责处理键盘事件、管理输入状态、协调拼音引擎和候选窗�?
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@class PinyinEngine;
@class CandidateWindow;
@class DictionaryManager;

/// 输入模式枚举
typedef NS_ENUM(NSInteger, InputMode) {
    InputModeEnglish,      // 英文模式
    InputModeChinese,      // 中文模式
    InputModeFullWidth,    // 全角模式
};

@interface InputController : IMKInputController

/// 当前输入模式
@property (nonatomic, assign) InputMode inputMode;

/// 拼音引擎
@property (nonatomic, strong) PinyinEngine *pinyinEngine;

/// 候选词窗口
@property (nonatomic, strong) CandidateWindow *candidateWindow;

/// 词库管理�?
@property (nonatomic, strong) DictionaryManager *dictionaryManager;

/// 当前输入的拼音字符串
@property (nonatomic, strong) NSMutableString *currentPinyin;

/// 当前选中的候选词索引
@property (nonatomic, assign) NSInteger selectedCandidateIndex;

/// 当前页的候选词列表
@property (nonatomic, strong) NSArray *currentPageCandidates;

/// 当前页码
@property (nonatomic, assign) NSInteger currentPage;

/// 每页候选词数量
@property (nonatomic, assign) NSInteger candidatesPerPage;

/// 是否处于组合输入状态（正在输入拼音�?
@property (nonatomic, assign) BOOL isComposing;

/// 获取当前控制器实�?
+ (instancetype)currentController;

/// 切换中英文输入模�?
- (void)toggleInputMode;

@end
