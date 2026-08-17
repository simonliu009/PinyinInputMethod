/*
 * PinyinInputMethod - macOS 拼音输入法
 * CandidateCell.m - 候选词单元格实现
 */

#import "CandidateCell.h"

static const CGFloat kCellPaddingH = 8.0;
static const CGFloat kCellPaddingV = 4.0;
static const CGFloat kCellCornerRadius = 4.0;
static const CGFloat kIndexTextSpacing = 2.0;

@implementation CandidateCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _font = [NSFont systemFontOfSize:14];
        _textColor = [NSColor blackColor];
        _selectedTextColor = [NSColor whiteColor];
        _backgroundColor = [NSColor clearColor];
        _selectedBackgroundColor = [NSColor systemBlueColor];
        _isSelected = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // 绘制背景
    NSColor *bgColor = _isSelected ? _selectedBackgroundColor : _backgroundColor;
    if (bgColor && bgColor != [NSColor clearColor]) {
        NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                             xRadius:kCellCornerRadius
                                                             yRadius:kCellCornerRadius];
        [bgColor setFill];
        [bgPath fill];
    }
    
    // 准备文本
    NSString *displayText;
    NSColor *drawColor;
    
    if (_indexText && _candidateText) {
        displayText = [NSString stringWithFormat:@"%@ %@", _indexText, _candidateText];
    } else {
        displayText = _candidateText ?: @"";
    }
    
    drawColor = _isSelected ? _selectedTextColor : _textColor;
    
    // 绘制文本
    NSDictionary *attrs = @{
        NSFontAttributeName: _font ?: [NSFont systemFontOfSize:14],
        NSForegroundColorAttributeName: drawColor ?: [NSColor blackColor],
    };
    
    NSSize textSize = [displayText sizeWithAttributes:attrs];
    NSPoint textPoint = NSMakePoint(
        kCellPaddingH + (self.bounds.size.width - textSize.width - kCellPaddingH * 2) / 2.0,
        kCellPaddingV
    );
    
    [displayText drawAtPoint:textPoint withAttributes:attrs];
}

+ (CGFloat)preferredWidthForText:(NSString *)text indexText:(NSString *)indexText font:(NSFont *)font {
    NSDictionary *attrs = @{ NSFontAttributeName: font ?: [NSFont systemFontOfSize:14] };
    
    NSString *fullText;
    if (indexText && text) {
        fullText = [NSString stringWithFormat:@"%@ %@", indexText, text];
    } else {
        fullText = text ?: @"";
    }
    
    NSSize textSize = [fullText sizeWithAttributes:attrs];
    return textSize.width + kCellPaddingH * 2;
}

@end
