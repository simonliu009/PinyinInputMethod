/*
 * PinyinInputMethod - macOS 拼音输入�?
 * UserDictionary.m - 用户自定义词库实�?
 */

#import "UserDictionary.h"
#import "DictionaryManager.h"

#pragma mark - CustomPhrase 实现

@implementation CustomPhrase

- (NSString *)description {
    return [NSString stringWithFormat:@"<CustomPhrase: %@ -> %@ (priority=%ld)>",
            _trigger, _phrase, (long)_priority];
}

@end

#pragma mark - UserDictionary 实现

@implementation UserDictionary {
    NSMutableArray<CustomPhrase *> *_customPhrases;
    NSString *_storagePath;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _customPhrases = [NSMutableArray array];
        
        // 设置存储路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(
            NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *appSupport = paths.firstObject;
        NSString *dir = [appSupport stringByAppendingPathComponent:@"PinyinInputMethod"];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        
        _storagePath = [dir stringByAppendingPathComponent:@"user_phrases.plist"];
        
        // 加载已保存的自定义短�?
        [self loadCustomPhrases];
        
        // 加载默认自定义短�?
        [self loadDefaultPhrases];
    }
    return self;
}

#pragma mark - 用户词操�?

- (BOOL)addWord:(NSString *)word pinyin:(NSString *)pinyin {
    return [[DictionaryManager sharedManager] addUserWord:word pinyin:pinyin];
}

- (BOOL)removeWord:(NSString *)word pinyin:(NSString *)pinyin {
    return [[DictionaryManager sharedManager] removeUserWord:word pinyin:pinyin];
}

- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin {
    return [[DictionaryManager sharedManager] queryWordsWithPinyin:pinyin];
}

#pragma mark - 自定义短�?

- (BOOL)addCustomPhrase:(CustomPhrase *)phrase {
    if (!phrase.trigger || !phrase.phrase) return NO;
    
    // 检查是否已存在
    for (CustomPhrase *existing in _customPhrases) {
        if ([existing.trigger isEqualToString:phrase.trigger]) {
            // 更新已有条目
            existing.phrase = phrase.phrase;
            existing.comment = phrase.comment;
            existing.priority = phrase.priority;
            [self saveCustomPhrases];
            return YES;
        }
    }
    
    [_customPhrases addObject:phrase];
    [self saveCustomPhrases];
    return YES;
}

- (BOOL)removeCustomPhraseWithTrigger:(NSString *)trigger {
    for (NSInteger i = _customPhrases.count - 1; i >= 0; i--) {
        CustomPhrase *phrase = _customPhrases[i];
        if ([phrase.trigger isEqualToString:trigger]) {
            [_customPhrases removeObjectAtIndex:i];
            [self saveCustomPhrases];
            return YES;
        }
    }
    return NO;
}

- (NSArray<CustomPhrase *> *)allCustomPhrases {
    return [_customPhrases copy];
}

- (NSString *)expandCustomPhrase:(NSString *)trigger {
    if (!trigger) return nil;
    
    NSString *lowerTrigger = [trigger lowercaseString];
    
    for (CustomPhrase *phrase in _customPhrases) {
        if ([[phrase.trigger lowercaseString] isEqualToString:lowerTrigger]) {
            return [self resolveDynamicPhrase:phrase.phrase];
        }
    }
    
    return nil;
}

/// 解析动态短语（包含日期、时间等变量�?
- (NSString *)resolveDynamicPhrase:(NSString *)phrase {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSDate *now = [NSDate date];
    
    NSString *result = [phrase copy];
    
    // 替换日期时间变量
    formatter.dateFormat = @"yyyy年MM月dd�?;
    result = [result stringByReplacingOccurrencesOfString:@"$DATE"
                                               withString:[formatter stringFromDate:now]];
    
    formatter.dateFormat = @"yyyy-MM-dd";
    result = [result stringByReplacingOccurrencesOfString:@"$DATE_SHORT"
                                               withString:[formatter stringFromDate:now]];
    
    formatter.dateFormat = @"HH:mm:ss";
    result = [result stringByReplacingOccurrencesOfString:@"$TIME"
                                               withString:[formatter stringFromDate:now]];
    
    formatter.dateFormat = @"HH:mm";
    result = [result stringByReplacingOccurrencesOfString:@"$TIME_SHORT"
                                               withString:[formatter stringFromDate:now]];
    
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    result = [result stringByReplacingOccurrencesOfString:@"$DATETIME"
                                               withString:[formatter stringFromDate:now]];
    
    // 星期
    NSArray *weekdays = @[@"星期�?, @"星期一", @"星期�?, @"星期�?, @"星期�?, @"星期�?, @"星期�?];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    result = [result stringByReplacingOccurrencesOfString:@"$WEEKDAY"
                                               withString:weekdays[weekday - 1]];
    
    return result;
}

#pragma mark - 持久�?

- (void)loadCustomPhrases {
    NSArray *saved = [NSArray arrayWithContentsOfFile:_storagePath];
    if (saved) {
        for (NSDictionary *dict in saved) {
            CustomPhrase *phrase = [[CustomPhrase alloc] init];
            phrase.trigger = dict[@"trigger"];
            phrase.phrase = dict[@"phrase"];
            phrase.comment = dict[@"comment"];
            phrase.priority = [dict[@"priority"] integerValue];
            [_customPhrases addObject:phrase];
        }
        NSLog(@"[UserDictionary] 加载�?%lu 条自定义短语", (unsigned long)_customPhrases.count);
    }
}

- (void)saveCustomPhrases {
    NSMutableArray *saved = [NSMutableArray arrayWithCapacity:_customPhrases.count];
    for (CustomPhrase *phrase in _customPhrases) {
        [saved addObject:@{
            @"trigger": phrase.trigger ?: @"",
            @"phrase": phrase.phrase ?: @"",
            @"comment": phrase.comment ?: @"",
            @"priority": @(phrase.priority),
        }];
    }
    [saved writeToFile:_storagePath atomically:YES];
}

- (void)loadDefaultPhrases {
    // 如果已有自定义短语，不加载默认�?
    if (_customPhrases.count > 0) return;
    
    // 默认自定义短�?
    NSArray *defaults = @[
        @{@"trigger": @"rq", @"phrase": @"$DATE", @"comment": @"日期", @"priority": @100},
        @{@"trigger": @"sj", @"phrase": @"$TIME", @"comment": @"时间", @"priority": @100},
        @{@"trigger": @"xq", @"phrase": @"$WEEKDAY", @"comment": @"星期", @"priority": @90},
        @{@"trigger": @"dt", @"phrase": @"$DATETIME", @"comment": @"日期时间", @"priority": @80},
        @{@"trigger": @"yj", @"phrase": @"$DATE_SHORT", @"comment": @"日期(�?", @"priority": @70},
    ];
    
    for (NSDictionary *dict in defaults) {
        CustomPhrase *phrase = [[CustomPhrase alloc] init];
        phrase.trigger = dict[@"trigger"];
        phrase.phrase = dict[@"phrase"];
        phrase.comment = dict[@"comment"];
        phrase.priority = [dict[@"priority"] integerValue];
        [_customPhrases addObject:phrase];
    }
    
    [self saveCustomPhrases];
}

#pragma mark - 导入导出

- (NSString *)exportAsText {
    NSMutableString *text = [NSMutableString string];
    [text appendString:@"# 用户自定义词库导出\n"];
    [text appendString:@"# 格式：trigger=phrase#comment\n\n"];
    
    // 导出用户�?
    [text appendString:@"## 用户词\n"];
    NSArray *userWords = [self queryWordsWithPinyin:@""];
    for (NSDictionary *word in userWords) {
        [text appendFormat:@"%@\t%@\n", word[@"word"], word[@"pinyin"]];
    }
    
    [text appendString:@"\n## 自定义短语\n"];
    for (CustomPhrase *phrase in _customPhrases) {
        [text appendFormat:@"%@=%@#%@\n", phrase.trigger, phrase.phrase, phrase.comment ?: @""];
    }
    
    return text;
}

- (BOOL)importFromText:(NSString *)text {
    NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;
        
        if ([trimmed containsString:@"="]) {
            // 自定义短语格式：trigger=phrase#comment
            NSArray *parts = [trimmed componentsSeparatedByString:@"="];
            if (parts.count >= 2) {
                CustomPhrase *phrase = [[CustomPhrase alloc] init];
                phrase.trigger = parts[0];
                
                NSString *rest = parts[1];
                NSArray *commentParts = [rest componentsSeparatedByString:@"#"];
                phrase.phrase = commentParts[0];
                phrase.comment = commentParts.count > 1 ? commentParts[1] : @"";
                phrase.priority = 50;
                
                [self addCustomPhrase:phrase];
            }
        } else if ([trimmed containsString:@"\t"]) {
            // 用户词格式：word\tpinyin
            NSArray *parts = [trimmed componentsSeparatedByString:@"\t"];
            if (parts.count >= 2) {
                [self addWord:parts[0] pinyin:parts[1]];
            }
        }
    }
    
    return YES;
}

@end
