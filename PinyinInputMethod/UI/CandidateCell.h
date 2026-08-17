/*
 * PinyinInputMethod - macOS 拼音输入�?
 * CandidateCell.h - 候选词单元�?
 *
 * 用于候选词窗口中每个候选词的绘�?
 */

#import <Cocoa/Cocoa.h>

@interface CandidateCell : NSView

/// 序号文本（如 "1." "2."�?
@property (nonatomic, copy) NSString *indexText;

/// 候选词文本
@property (nonatomic, copy) NSString *candidateText;

/// 是否处于选中状�?
@property (nonatomic, assign) BOOL isSelected;

/// 候选词字体
@property (nonatomic, strong) NSFont *font;

/// 文字颜色
@property (nonatomic, strong) NSColor *textColor;

/// 选中时的文字颜色
@property (nonatomic, strong) NSColor *selectedTextColor;

/// 背景颜色
@property (nonatomic, strong) NSColor *backgroundColor;

/// 选中时的背景颜色
@property (nonatomic, strong) NSColor *selectedBackgroundColor;

/// 计算候选词所需的最小宽�?
+ (CGFloat)preferredWidthForText:(NSString *)text indexText:(NSString *)indexText font:(NSFont *)font;

@end
