/*
 * PinyinInputMethod - macOS 拼音输入�?
 * DictionaryManager.m - 词库管理器实�?
 */

#import "DictionaryManager.h"
#import "DictionaryDB.h"
#import "SogouSCelParser.h"

static DictionaryManager *sharedInstance = nil;

@implementation DictionaryManager

+ (instancetype)sharedManager {
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        sharedInstance = self;
        
        // 初始化查询缓�?
        _queryCache = [[NSCache alloc] init];
        _queryCache.countLimit = 500;  // 最多缓�?500 个拼音的查询结果
        _cacheLimit = 500;
    }
    return self;
}

#pragma mark - 初始�?

- (void)initializeDatabases {
    // 获取数据目录
    NSString *dataDir = [self dataDirectory];
    
    // 确保目录存在
    [[NSFileManager defaultManager] createDirectoryAtPath:dataDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    // 初始化主词库数据�?
    NSString *mainDBPath = [dataDir stringByAppendingPathComponent:@"dictionary.db"];
    _mainDB = [[DictionaryDB alloc] initWithPath:mainDBPath];
    
    // 初始化用户习惯数据库
    NSString *habitsDBPath = [dataDir stringByAppendingPathComponent:@"habits.db"];
    _habitsDB = [[DictionaryDB alloc] initWithPath:habitsDBPath];
    
    // 检查是否需要初始化基础词库
    if ([_mainDB totalWordCount] == 0) {
        [self loadBaseDictionary];
    }
    
    NSLog(@"[DictionaryManager] 词库初始化完成，�?%ld 条词�?, (long)[_mainDB totalWordCount]);
}

- (void)closeDatabases {
    [_mainDB close];
    [_habitsDB close];
}

#pragma mark - 数据目录

- (NSString *)dataDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = paths.firstObject;
    return [appSupport stringByAppendingPathComponent:@"PinyinInputMethod"];
}

#pragma mark - 基础词库加载

- (void)loadBaseDictionary {
    NSLog(@"[DictionaryManager] 加载基础词库...");
    
    // 尝试�?Bundle 中加载预编译的词�?
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"pinyin_base" ofType:@"db"];
    
    if (bundlePath) {
        // 直接复制预编译的数据�?
        NSString *destPath = [[self dataDirectory] stringByAppendingPathComponent:@"dictionary.db"];
        [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:destPath error:nil];
        
        // 重新打开数据�?
        [_mainDB close];
        _mainDB = [[DictionaryDB alloc] initWithPath:destPath];
    } else {
        // 从文本文件加�?
        NSString *textPath = [[NSBundle mainBundle] pathForResource:@"pinyin_map" ofType:@"txt"];
        if (textPath) {
            [self importTextDictionary:textPath source:DictionarySourceBase];
        } else {
            NSLog(@"[DictionaryManager] 警告：未找到基础词库文件");
            [self loadMinimalBaseDictionary];
        }
    }
}

/// 加载最小基础词库（内置常用单字）
- (void)loadMinimalBaseDictionary {
    NSLog(@"[DictionaryManager] 加载内置最小词�?..");
    
    // 常用单字及其拼音（约 3000 个常用字的核心子集）
    NSArray *baseWords = @[
        // 高频单字
        @{@"word": @"�?, @"pinyin": @"de", @"frequency": @1000000},
        @{@"word": @"一", @"pinyin": @"yi", @"frequency": @900000},
        @{@"word": @"�?, @"pinyin": @"shi", @"frequency": @850000},
        @{@"word": @"�?, @"pinyin": @"bu", @"frequency": @800000},
        @{@"word": @"�?, @"pinyin": @"le", @"frequency": @780000},
        @{@"word": @"�?, @"pinyin": @"zai", @"frequency": @750000},
        @{@"word": @"�?, @"pinyin": @"ren", @"frequency": @720000},
        @{@"word": @"�?, @"pinyin": @"you", @"frequency": @700000},
        @{@"word": @"�?, @"pinyin": @"wo", @"frequency": @680000},
        @{@"word": @"�?, @"pinyin": @"ta", @"frequency": @660000},
        @{@"word": @"�?, @"pinyin": @"zhe", @"frequency": @640000},
        @{@"word": @"�?, @"pinyin": @"zhong", @"frequency": @620000},
        @{@"word": @"�?, @"pinyin": @"da", @"frequency": @600000},
        @{@"word": @"�?, @"pinyin": @"lai", @"frequency": @580000},
        @{@"word": @"�?, @"pinyin": @"shang", @"frequency": @560000},
        @{@"word": @"�?, @"pinyin": @"guo", @"frequency": @540000},
        @{@"word": @"�?, @"pinyin": @"ge", @"frequency": @520000},
        @{@"word": @"�?, @"pinyin": @"dao", @"frequency": @500000},
        @{@"word": @"�?, @"pinyin": @"shuo", @"frequency": @480000},
        @{@"word": @"�?, @"pinyin": @"men", @"frequency": @460000},
        // 常用双字�?
        @{@"word": @"我们", @"pinyin": @"wo men", @"frequency": @450000},
        @{@"word": @"中国", @"pinyin": @"zhong guo", @"frequency": @440000},
        @{@"word": @"可以", @"pinyin": @"ke yi", @"frequency": @430000},
        @{@"word": @"什�?, @"pinyin": @"shen me", @"frequency": @420000},
        @{@"word": @"自己", @"pinyin": @"zi ji", @"frequency": @410000},
        @{@"word": @"知道", @"pinyin": @"zhi dao", @"frequency": @400000},
        @{@"word": @"现在", @"pinyin": @"xian zai", @"frequency": @390000},
        @{@"word": @"没有", @"pinyin": @"mei you", @"frequency": @380000},
        @{@"word": @"因为", @"pinyin": @"yin wei", @"frequency": @370000},
        @{@"word": @"所�?, @"pinyin": @"suo yi", @"frequency": @360000},
        @{@"word": @"这个", @"pinyin": @"zhe ge", @"frequency": @350000},
        @{@"word": @"工作", @"pinyin": @"gong zuo", @"frequency": @340000},
        @{@"word": @"已经", @"pinyin": @"yi jing", @"frequency": @330000},
        @{@"word": @"学习", @"pinyin": @"xue xi", @"frequency": @320000},
        @{@"word": @"问题", @"pinyin": @"wen ti", @"frequency": @310000},
        @{@"word": @"生活", @"pinyin": @"sheng huo", @"frequency": @300000},
        @{@"word": @"时间", @"pinyin": @"shi jian", @"frequency": @290000},
        @{@"word": @"朋友", @"pinyin": @"peng you", @"frequency": @280000},
        @{@"word": @"事情", @"pinyin": @"shi qing", @"frequency": @270000},
        @{@"word": @"觉得", @"pinyin": @"jue de", @"frequency": @260000},
        @{@"word": @"使用", @"pinyin": @"shi yong", @"frequency": @250000},
        @{@"word": @"出来", @"pinyin": @"chu lai", @"frequency": @240000},
        @{@"word": @"开�?, @"pinyin": @"kai shi", @"frequency": @230000},
        @{@"word": @"每天", @"pinyin": @"mei tian", @"frequency": @220000},
        @{@"word": @"公司", @"pinyin": @"gong si", @"frequency": @210000},
        @{@"word": @"社会", @"pinyin": @"she hui", @"frequency": @200000},
        @{@"word": @"发展", @"pinyin": @"fa zhan", @"frequency": @190000},
        @{@"word": @"经济", @"pinyin": @"jing ji", @"frequency": @180000},
        @{@"word": @"教育", @"pinyin": @"jiao yu", @"frequency": @170000},
        @{@"word": @"文化", @"pinyin": @"wen hua", @"frequency": @160000},
        @{@"word": @"输入", @"pinyin": @"shu ru", @"frequency": @150000},
        @{@"word": @"方法", @"pinyin": @"fang fa", @"frequency": @140000},
        @{@"word": @"拼音", @"pinyin": @"pin yin", @"frequency": @130000},
    ];
    
    [_mainDB insertWords:baseWords];
    
    NSLog(@"[DictionaryManager] 最小基础词库加载完成，共 %lu �?, (unsigned long)baseWords.count);
}

#pragma mark - 查询

- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin {
    if (!pinyin || pinyin.length == 0) return @[];
    
    NSString *lower = [pinyin lowercaseString];
    
    // 先查内存缓存
    NSArray *cached = [_queryCache objectForKey:lower];
    if (cached) {
        return cached;
    }
    
    // 缓存未命中，查数据库
    NSArray *exactResults = [_mainDB queryWordsWithPinyin:lower];
    
    // 再查用户习惯
    NSArray *habits = [self getUserHabitsForPinyin:lower];
    
    // 合并结果（习惯词优先�?
    NSMutableArray *merged = [NSMutableArray array];
    
    for (NSDictionary *habit in habits) {
        NSMutableDictionary *entry = [habit mutableCopy];
        entry[@"source"] = @(DictionarySourceUser);
        entry[@"frequency"] = @([entry[@"hit_count"] integerValue] * 10000);
        [merged addObject:entry];
    }
    
    for (NSDictionary *word in exactResults) {
        BOOL exists = NO;
        for (NSDictionary *existing in merged) {
            if ([existing[@"word"] isEqualToString:word[@"word"]]) {
                exists = YES;
                break;
            }
        }
        if (!exists) {
            [merged addObject:word];
        }
    }
    
    // 存入缓存
    NSArray *result = [merged copy];
    [_queryCache setObject:result forKey:lower];
    
    return result;
}

- (NSArray<NSDictionary *> *)queryWordsWithPrefix:(NSString *)prefix limit:(NSInteger)limit {
    return [_mainDB queryWordsWithPinyinPrefix:prefix limit:limit];
}

#pragma mark - 搜狗导入

- (BOOL)importSogouSCel:(NSString *)filePath 
          progressHandler:(void(^)(float progress, NSInteger count))progressHandler
          completionHandler:(void(^)(BOOL success, NSInteger importedCount))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SogouSCelParser *parser = [[SogouSCelParser alloc] init];
        
        // 解析 .scel 文件
        NSArray<NSDictionary *> *words = [parser parseFile:filePath 
                                             progressHandler:progressHandler];
        
        if (!words || words.count == 0) {
            NSLog(@"[DictionaryManager] 搜狗词库解析失败或为�?);
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO, 0);
                });
            }
            return;
        }
        
        // 设置来源为搜�?
        NSMutableArray *taggedWords = [NSMutableArray arrayWithCapacity:words.count];
        for (NSDictionary *word in words) {
            NSMutableDictionary *tagged = [word mutableCopy];
            tagged[@"source"] = @(DictionarySourceSogou);
            [taggedWords addObject:tagged];
        }
        
        // 批量插入数据�?
        BOOL success = [self->_mainDB insertWords:taggedWords];
        
        // 导入成功后清空缓�?
        if (success) {
            [self clearCache];
        }
        
        NSLog(@"[DictionaryManager] 搜狗词库导入完成，共 %lu �?, (unsigned long)taggedWords.count);
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success, taggedWords.count);
            });
        }
    });
    
    return YES;
}

#pragma mark - 文本导入

- (BOOL)importTextDictionary:(NSString *)filePath source:(DictionarySource)source {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (error) {
        NSLog(@"[DictionaryManager] 读取文件失败: %@", error);
        return NO;
    }
    
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *words = [NSMutableArray array];
    
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;
        
        // 格式：词语\t拼音\t词频 �?词语 拼音 词频
        NSArray *parts = [trimmed componentsSeparatedByCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (parts.count >= 2) {
            NSString *word = parts[0];
            NSString *pinyin = parts[1];
            NSInteger freq = parts.count >= 3 ? [parts[2] integerValue] : 1000;
            
            [words addObject:@{
                @"word": word,
                @"pinyin": pinyin,
                @"frequency": @(freq),
                @"source": @(source),
            }];
        }
    }
    
    if (words.count > 0) {
        return [_mainDB insertWords:words];
    }
    
    return NO;
}

#pragma mark - 用户词库

- (BOOL)addUserWord:(NSString *)word pinyin:(NSString *)pinyin {
    return [_mainDB insertWord:word pinyin:pinyin frequency:10000 source:DictionarySourceUser];
}

- (BOOL)removeUserWord:(NSString *)word pinyin:(NSString *)pinyin {
    return [_mainDB deleteWord:word pinyin:pinyin];
}

- (BOOL)recordUserHabitWithPinyin:(NSString *)pinyin word:(NSString *)word {
    return [_habitsDB recordUserHabit:pinyin word:word];
}

- (NSArray<NSDictionary *> *)getUserHabitsForPinyin:(NSString *)pinyin {
    return [_habitsDB getUserHabitsForPinyin:pinyin limit:10];
}

#pragma mark - 词库管理

- (NSInteger)totalWordCount {
    return [_mainDB totalWordCount];
}

- (NSDictionary<NSString *, NSNumber *> *)wordCountBySource {
    return @{
        @"基础词库": @([_mainDB wordCountForSource:DictionarySourceBase]),
        @"搜狗词库": @([_mainDB wordCountForSource:DictionarySourceSogou]),
        @"用户词库": @([_mainDB wordCountForSource:DictionarySourceUser]),
    };
}

- (BOOL)clearDictionaryForSource:(DictionarySource)source {
    BOOL result = [_mainDB deleteWordsWithSource:source];
    if (result) {
        [self clearCache];  // 词库变更后清空缓�?
    }
    return result;
}

- (BOOL)exportDictionaryToPath:(NSString *)filePath source:(DictionarySource)source {
    // 查询所有指定来源的词条
    NSArray *words = [_mainDB queryWordsWithPinyinPrefix:@"" limit:999999];
    
    NSMutableString *content = [NSMutableString string];
    [content appendString:@"# 拼音输入法词库导出\n"];
    [content appendString:@"# 格式：词�?拼音 词频\n\n"];
    
    for (NSDictionary *word in words) {
        if ([word[@"source"] integerValue] == source) {
            [content appendFormat:@"%@\t%@\t%@\n", 
                word[@"word"], word[@"pinyin"], word[@"frequency"]];
        }
    }
    
    return [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - 缓存管理

- (void)clearCache {
    [_queryCache removeAllObjects];
    NSLog(@"[DictionaryManager] 查询缓存已清�?);
}

- (void)warmUpCache {
    NSLog(@"[DictionaryManager] 开始预热缓�?..");
    
    // 加载最高频的拼音对应的词条到缓�?
    // 查询词频最高的�?2000 个词条，提取其拼音加入缓�?
    NSArray *topWords = [_mainDB queryWordsWithPinyinPrefix:@"" limit:2000];
    
    NSMutableSet<NSString *> *pinyins = [NSMutableSet set];
    for (NSDictionary *word in topWords) {
        NSString *py = word[@"pinyin"];
        if (py) {
            [pinyins addObject:py];
            // 也缓存单字拼�?
            NSArray *parts = [py componentsSeparatedByString:@" "];
            for (NSString *part in parts) {
                [pinyins addObject:part];
            }
        }
    }
    
    // 预加载这些拼音的查询结果
    NSInteger warmed = 0;
    for (NSString *pinyin in pinyins) {
        if (warmed >= _cacheLimit) break;
        [self queryWordsWithPinyin:pinyin];  // 这会触发缓存填充
        warmed++;
    }
    
    NSLog(@"[DictionaryManager] 缓存预热完成，已加载 %ld 个拼音查询结�?, (long)warmed);
}

@end
