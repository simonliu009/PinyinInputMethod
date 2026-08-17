/*
 * PinyinInputMethod - macOS 拼音输入�?
 * DictionaryManager.h - 词库管理�?
 *
 * 统一管理基础词库、用户词库和搜狗导入词库
 */

#import <Foundation/Foundation.h>

@class DictionaryDB;

/// 词库来源枚举
typedef NS_ENUM(NSInteger, DictionarySource) {
    DictionarySourceBase = 0,     // 基础词库
    DictionarySourceSogou = 1,    // 搜狗导入
    DictionarySourceUser = 2,     // 用户自定�?
};

@interface DictionaryManager : NSObject

/// 主数据库
@property (nonatomic, strong) DictionaryDB *mainDB;

/// 用户习惯数据�?
@property (nonatomic, strong) DictionaryDB *habitsDB;

/// 内存缓存（拼�?-> 候选词列表），用于加速高频查�?
@property (nonatomic, strong) NSCache *queryCache;

/// 缓存最大条目数（默�?500�?
@property (nonatomic, assign) NSInteger cacheLimit;

/// 获取单例
+ (instancetype)sharedManager;

/// 初始化数据库（加载基础词库�?
- (void)initializeDatabases;

/// 关闭数据�?
- (void)closeDatabases;

#pragma mark - 查询

/// 根据拼音查询词条
- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin;

/// 根据拼音前缀查询
- (NSArray<NSDictionary *> *)queryWordsWithPrefix:(NSString *)prefix limit:(NSInteger)limit;

#pragma mark - 导入

/// 导入搜狗 .scel 文件
- (BOOL)importSogouSCel:(NSString *)filePath 
           progressHandler:(void(^)(float progress, NSInteger count))progressHandler
           completionHandler:(void(^)(BOOL success, NSInteger importedCount))completionHandler;

/// 导入文本格式词库（每行格式：词语 拼音 词频�?
- (BOOL)importTextDictionary:(NSString *)filePath 
                      source:(DictionarySource)source;

#pragma mark - 用户词库

/// 添加用户自定义词
- (BOOL)addUserWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 删除用户自定义词
- (BOOL)removeUserWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 记录用户选择习惯
- (BOOL)recordUserHabitWithPinyin:(NSString *)pinyin word:(NSString *)word;

/// 获取用户习惯�?
- (NSArray<NSDictionary *> *)getUserHabitsForPinyin:(NSString *)pinyin;

#pragma mark - 词库管理

/// 获取词条总数
- (NSInteger)totalWordCount;

/// 获取各来源词条数
- (NSDictionary<NSString *, NSNumber *> *)wordCountBySource;

/// 清空指定来源的词�?
- (BOOL)clearDictionaryForSource:(DictionarySource)source;

/// 导出词库为文本文�?
- (BOOL)exportDictionaryToPath:(NSString *)filePath source:(DictionarySource)source;

#pragma mark - 缓存管理

/// 清空查询缓存
- (void)clearCache;

/// 预热缓存（加载高频词条到内存�?
- (void)warmUpCache;

@end
