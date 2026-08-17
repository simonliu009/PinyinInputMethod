/*
 * PinyinInputMethod - macOS 拼音输入法
 * CandidateWindow.m - 候选词窗口实现
 */

#import "CandidateWindow.h"

// 窗口尺寸常量
static const CGFloat kCandidateHeight = 32.0;
static const CGFloat kCandidatePadding = 8.0;
static const CGFloat kCandidateSpacing = 4.0;
static const CGFloat kItemPaddingH = 10.0;
static const CGFloat kItemPaddingV = 4.0;
static const CGFloat kBorderWidth = 1.0;
static const CGFloat kCornerRadius = 6.0;

@interface CandidateView : NSView
@property (nonatomic, strong) NSArray<NSString *> *candidates;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSFont *candidateFont;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *selectedBackgroundColor;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *selectedTextColor;
@end

@implementation CandidateView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // 绘制圆角背景
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                           xRadius:kCornerRadius
                                                           yRadius:kCornerRadius];
    [self.backgroundColor setFill];
    [bgPath fill];
    
    // 绘制边框
    [[NSColor colorWithWhite:0.7 alpha:0.5] setStroke];
    bgPath.lineWidth = kBorderWidth;
    [bgPath stroke];
    
    // 绘制候选词
    if (!self.candidates || self.candidates.count == 0) return;
    
    CGFloat x = kCandidatePadding;
    CGFloat y = (self.bounds.size.height - kCandidateHeight) / 2.0;
    
    for (NSInteger i = 0; i < (NSInteger)self.candidates.count; i++) {
        NSString *text = self.candidates[i];
        
        // 计算文本宽度
        NSDictionary *attrs;
        if (i == self.selectedIndex) {
            attrs = @{
                NSFontAttributeName: self.candidateFont ?: [NSFont systemFontOfSize:14],
                NSForegroundColorAttributeName: self.selectedTextColor ?: [NSColor whiteColor],
            };
            
            // 绘制选中背景
            NSSize textSize = [text sizeWithAttributes:attrs];
            NSRect itemRect = NSMakeRect(x - kItemPaddingH/2, y,
                                         textSize.width + kItemPaddingH, kCandidateHeight);
            
            NSBezierPath *itemPath = [NSBezierPath bezierPathWithRoundedRect:itemRect
                                                                   xRadius:4 yRadius:4];
            [self.selectedBackgroundColor setFill];
            [itemPath fill];
        } else {
            attrs = @{
                NSFontAttributeName: self.candidateFont ?: [NSFont systemFontOfSize:14],
                NSForegroundColorAttributeName: self.textColor ?: [NSColor blackColor],
            };
        }
        
        // 绘制文本
        NSPoint textPoint = NSMakePoint(x, y + kItemPaddingV);
        [text drawAtPoint:textPoint withAttributes:attrs];
        
        // 计算下一个位置
        NSSize textSize = [text sizeWithAttributes:attrs];
        x += textSize.width + kCandidateSpacing + kItemPaddingH;
    }
}

- (BOOL)isFlipped {
    return NO;
}

@end

@implementation CandidateWindow

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 400, kCandidateHeight + kCandidatePadding * 2);
    
    self = [super initWithContentRect:frame
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        // 窗口属性
        [self setLevel:NSFloatingWindowLevel];
        [self setFloatingPanel:YES];
        [self setHidesOnDeactivate:NO];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setIgnoresMouseEvents:NO];
        [self setHasShadow:YES];
        
        // 默认样式
        _candidateFont = [NSFont systemFontOfSize:14];
        _pinyinFont = [NSFont systemFontOfSize:11];
        _candidateBackgroundColor = [NSColor colorWithWhite:0.98 alpha:0.95];
        _selectedBackgroundColor = [NSColor systemBlueColor];
        _textColor = [NSColor blackColor];
        _selectedTextColor = [NSColor whiteColor];
        
        _selectedIndex = 0;
        _currentPage = 0;
        _totalPages = 1;
        
        // 创建候选词视图
        CandidateView *view = [[CandidateView alloc] initWithFrame:frame];
        view.candidateFont = _candidateFont;
        view.backgroundColor = _candidateBackgroundColor;
        view.selectedBackgroundColor = _selectedBackgroundColor;
        view.textColor = _textColor;
        view.selectedTextColor = _selectedTextColor;
        [self setContentView:view];
    }
    return self;
}

- (void)showWithCandidates:(NSArray<NSString *> *)candidates
                atPosition:(NSPoint)position
                    client:(id)client
{
    _candidates = candidates;
    _selectedIndex = 0;
    
    // 更新视图
    CandidateView *view = (CandidateView *)[self contentView];
    view.candidates = candidates;
    view.selectedIndex = _selectedIndex;
    view.candidateFont = _candidateFont;
    view.backgroundColor = _candidateBackgroundColor;
    view.selectedBackgroundColor = _selectedBackgroundColor;
    view.textColor = _textColor;
    view.selectedTextColor = _selectedTextColor;
    
    // 计算窗口宽度
    CGFloat totalWidth = [self calculateTotalWidth:candidates];
    totalWidth = MAX(totalWidth + kCandidatePadding * 2, 100);
    
    // 更新窗口大小和位置
    NSRect frame = NSMakeRect(position.x, position.y - kCandidateHeight - kCandidatePadding * 2 - 4,
                              totalWidth, kCandidateHeight + kCandidatePadding * 2);
    [self setFrame:frame display:YES];
    
    [view setNeedsDisplay:YES];
    [self orderFront:nil];
}

- (void)orderOut:(id)sender {
    [super orderOut:sender];
}

- (void)updateDisplay {
    CandidateView *view = (CandidateView *)[self contentView];
    view.candidates = _candidates;
    view.selectedIndex = _selectedIndex;
    [view setNeedsDisplay:YES];
}

- (void)setCurrentPage:(NSInteger)page totalPages:(NSInteger)total {
    _currentPage = page;
    _totalPages = total;
    [self updateDisplay];
}

#pragma mark - 辅助方法

- (CGFloat)calculateTotalWidth:(NSArray<NSString *> *)candidates {
    CGFloat totalWidth = 0;
    NSDictionary *attrs = @{
        NSFontAttributeName: _candidateFont ?: [NSFont systemFontOfSize:14],
    };
    
    for (NSString *text in candidates) {
        NSSize textSize = [text sizeWithAttributes:attrs];
        totalWidth += textSize.width + kItemPaddingH + kCandidateSpacing;
    }
    
    return totalWidth;
}

#pragma mark - 鼠标事件

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertRectFromScreen:[event window] ? [event window].frame : NSZeroRect].origin;
    location = [event locationInWindow];
    
    // 计算点击了哪个候选词
    CGFloat x = kCandidatePadding;
    CandidateView *view = (CandidateView *)[self contentView];
    
    NSDictionary *attrs = @{
        NSFontAttributeName: _candidateFont ?: [NSFont systemFontOfSize:14],
    };
    
    for (NSInteger i = 0; i < (NSInteger)_candidates.count; i++) {
        NSSize textSize = [_candidates[i] sizeWithAttributes:attrs];
        CGFloat itemWidth = textSize.width + kItemPaddingH;
        
        if (location.x >= x && location.x <= x + itemWidth) {
            _selectedIndex = i;
            [view setNeedsDisplay:YES];
            
            // 通知 InputController 选中了候选词
            // 通过 NSNotification 传递
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CandidateSelected"
                                                               object:@(i)];
            break;
        }
        
        x += itemWidth + kCandidateSpacing;
    }
}

@end
