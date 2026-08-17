/*
 * PinyinInputMethod - macOS 拼音输入法
 * CandidateWindow.h - 候选词窗口
 *
 * 浮动候选词窗口，跟随光标位置显示
 */

#import <Cocoa/Cocoa.h>

@interface CandidateWindow : NSPanel

/// 候选词列表（已格式化的显示文本）
@property (nonatomic, strong) NSArray<NSString *> *candidates;

/// 当前选中索引
@property (nonatomic, assign) NSInteger selectedIndex;

/// 当前页码
@property (nonatomic, assign) NSInteger currentPage;

/// 总页数
@property (nonatomic, assign) NSInteger totalPages;

/// 候选词字体
@property (nonatomic, strong) NSFont *candidateFont;

/// 拼音字体
@property (nonatomic, strong) NSFont *pinyinFont;

/// 背景颜色
@property (nonatomic, strong) NSColor *backgroundColor;

/// 选中项背景颜色
@property (nonatomic, strong) NSColor *selectedBackgroundColor;

/// 文字颜色
@property (nonatomic, strong) NSColor *textColor;

/// 选中项文字颜色
@property (nonatomic, strong) NSColor *selectedTextColor;

/// 初始化
- (instancetype)init;

/// 显示候选词
- (void)showWithCandidates:(NSArray<NSString *> *)candidates
                atPosition:(NSPoint)position
                    client:(id)client;

/// 隐藏窗口
- (void)orderOut:(id)sender;

/// 更新显示
- (void)updateDisplay;

/// 设置页码信息
- (void)setCurrentPage:(NSInteger)page totalPages:(NSInteger)total;

@end
