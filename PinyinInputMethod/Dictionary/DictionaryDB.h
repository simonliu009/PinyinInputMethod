/*
 * PinyinInputMethod - macOS 拼音输入�?
 * DictionaryDB.h - SQLite 数据库操�?
 *
 * 负责词库数据的存储和查询
 */

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DictionaryDB : NSObject

/// 数据库文件路�?
@property (nonatomic, copy) NSString *databasePath;

/// 初始化数据库（如果不存在则创建）
- (instancetype)initWithPath:(NSString *)path;

/// 打开数据�?
- (BOOL)open;

/// 关闭数据�?
- (void)close;

/// 创建表结�?
- (BOOL)createTables;

#pragma mark - 词条操作

/// 插入词条
- (BOOL)insertWord:(NSString *)word pinyin:(NSString *)pinyin 
         frequency:(NSInteger)frequency source:(NSInteger)source;

/// 批量插入词条（事务包裹）
- (BOOL)insertWords:(NSArray<NSDictionary *> *)words;

/// 根据拼音查询词条
- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin;

/// 根据拼音前缀查询词条
- (NSArray<NSDictionary *> *)queryWordsWithPinyinPrefix:(NSString *)prefix limit:(NSInteger)limit;

/// 更新词频
- (BOOL)updateFrequency:(NSInteger)frequency forWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 删除词条
- (BOOL)deleteWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 删除指定来源的所有词�?
- (BOOL)deleteWordsWithSource:(NSInteger)source;

#pragma mark - 用户习惯

/// 记录用户选择
- (BOOL)recordUserHabit:(NSString *)pinyin word:(NSString *)word;

/// 获取用户对某拼音的习惯词
- (NSArray<NSDictionary *> *)getUserHabitsForPinyin:(NSString *)pinyin limit:(NSInteger)limit;

#pragma mark - 统计

/// 获取词条总数
- (NSInteger)totalWordCount;

/// 获取指定来源的词条数
- (NSInteger)wordCountForSource:(NSInteger)source;

@end
