/*
 * PinyinInputMethod - macOS 拼音输入法
 * FuzzyMatcher.m - 模糊音匹配器实现
 */

#import "FuzzyMatcher.h"
#import "ConfigManager.h"

@implementation FuzzyMatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        // 从配置中加载模糊音设置
        ConfigManager *config = [ConfigManager sharedManager];
        _fuzzyZ_ZH  = [config boolForKey:@"fuzzyZ_ZH"  defaultValue:NO];
        _fuzzyC_CH  = [config boolForKey:@"fuzzyC_CH"  defaultValue:NO];
        _fuzzyS_SH  = [config boolForKey:@"fuzzyS_SH"  defaultValue:NO];
        _fuzzyN_L   = [config boolForKey:@"fuzzyN_L"   defaultValue:NO];
        _fuzzyF_H   = [config boolForKey:@"fuzzyF_H"   defaultValue:NO];
        _fuzzyAn_Ang = [config boolForKey:@"fuzzyAn_Ang" defaultValue:NO];
        _fuzzyEn_Eng = [config boolForKey:@"fuzzyEn_Eng" defaultValue:NO];
        _fuzzyIn_In  = [config boolForKey:@"fuzzyIn_In"  defaultValue:NO];
        
        [self buildFuzzyMap];
    }
    return self;
}

#pragma mark - 模糊音映射表构建

- (void)buildFuzzyMap {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    // z/zh 模糊
    if (_fuzzyZ_ZH) {
        // z -> zh 的映射
        [self addFuzzyPair:@"z" alternative:@"zh" toMap:map];
    }
    
    // c/ch 模糊
    if (_fuzzyC_CH) {
        [self addFuzzyPair:@"c" alternative:@"ch" toMap:map];
    }
    
    // s/sh 模糊
    if (_fuzzyS_SH) {
        [self addFuzzyPair:@"s" alternative:@"sh" toMap:map];
    }
    
    // n/l 模糊
    if (_fuzzyN_L) {
        [self addFuzzyPair:@"n" alternative:@"l" toMap:map];
    }
    
    // f/h 模糊
    if (_fuzzyF_H) {
        [self addFuzzyPair:@"f" alternative:@"h" toMap:map];
    }
    
    _fuzzyMap = map;
}

- (void)addFuzzyPair:(NSString *)initial alternative:(NSString *)alt toMap:(NSMutableDictionary *)map {
    // 双向映射
    NSMutableArray *existing1 = map[initial] ?: [NSMutableArray array];
    [existing1 addObject:alt];
    map[initial] = existing1;
    
    NSMutableArray *existing2 = map[alt] ?: [NSMutableArray array];
    [existing2 addObject:initial];
    map[alt] = existing2;
}

#pragma mark - 模糊音替代

- (NSArray<NSString *> *)getFuzzyAlternativesForPinyin:(NSString *)pinyin {
    if (!pinyin || pinyin.length == 0) return @[];
    
    NSString *lower = [pinyin lowercaseString];
    NSMutableArray<NSString *> *alternatives = [NSMutableArray array];
    
    // 提取声母
    NSString *initial = [self extractInitial:lower];
    NSString *final = [lower substringFromIndex:initial.length];
    
    // 声母替换
    NSArray *initialAlts = _fuzzyMap[initial];
    if (initialAlts) {
        for (NSString *altInitial in initialAlts) {
            NSString *altPinyin = [altInitial stringByAppendingString:final];
            [alternatives addObject:altPinyin];
        }
    }
    
    // 韵母模糊匹配
    if (_fuzzyAn_Ang) {
        [self addRimeAlternatives:final prefix:initial 
                       suffix1:@"an" suffix2:@"ang" 
                    toAlternatives:alternatives];
    }
    if (_fuzzyEn_Eng) {
        [self addRimeAlternatives:final prefix:initial 
                       suffix1:@"en" suffix2:@"eng" 
                    toAlternatives:alternatives];
    }
    if (_fuzzyIn_In) {
        [self addRimeAlternatives:final prefix:initial 
                       suffix1:@"in" suffix2:@"ing" 
                    toAlternatives:alternatives];
    }
    
    return alternatives;
}

- (void)addRimeAlternatives:(NSString *)final 
                     prefix:(NSString *)prefix
                    suffix1:(NSString *)s1 
                    suffix2:(NSString *)s2
             toAlternatives:(NSMutableArray *)alternatives 
{
    if ([final hasSuffix:s1]) {
        NSString *newFinal = [final substringToIndex:final.length - s1.length];
        newFinal = [newFinal stringByAppendingString:s2];
        [alternatives addObject:[prefix stringByAppendingString:newFinal]];
    } else if ([final hasSuffix:s2]) {
        NSString *newFinal = [final substringToIndex:final.length - s2.length];
        newFinal = [newFinal stringByAppendingString:s1];
        [alternatives addObject:[prefix stringByAppendingString:newFinal]];
    }
}

- (BOOL)isFuzzyMatch:(NSString *)pinyin1 withPinyin:(NSString *)pinyin2 {
    if (!pinyin1 || !pinyin2) return NO;
    
    NSString *lower1 = [pinyin1 lowercaseString];
    NSString *lower2 = [pinyin2 lowercaseString];
    
    // 完全匹配
    if ([lower1 isEqualToString:lower2]) return YES;
    
    // 检查是否为模糊音对
    NSArray *alts = [self getFuzzyAlternativesForPinyin:lower1];
    return [alts containsObject:lower2];
}

#pragma mark - 辅助方法

- (NSString *)extractInitial:(NSString *)pinyin {
    if (pinyin.length == 0) return @"";
    
    // 检查双字母声母
    if (pinyin.length >= 2) {
        NSString *two = [pinyin substringToIndex:2];
        if ([two isEqualToString:@"zh"] || 
            [two isEqualToString:@"ch"] || 
            [two isEqualToString:@"sh"]) {
            return two;
        }
    }
    
    // 检查单字母声母
    NSString *one = [pinyin substringToIndex:1];
    static NSSet *initialSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initialSet = [NSSet setWithArray:@[
            @"b", @"p", @"m", @"f", @"d", @"t", @"n", @"l",
            @"g", @"k", @"h", @"j", @"q", @"x",
            @"r", @"z", @"c", @"s", @"y", @"w"
        ]];
    });
    
    if ([initialSet containsObject:one]) {
        return one;
    }
    
    return @"";  // 零声母
}

@end
