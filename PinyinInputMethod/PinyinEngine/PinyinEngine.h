/*
 * PinyinInputMethod - macOS 拼音输入法
 * PinyinEngine.h - 拼音引擎主类
 *
 * 负责拼音解析、候选词生成、排序和用户习惯学习
 */

#import <Foundation/Foundation.h>

@class DictionaryManager;
@class PinyinParser;
@class CandidateRanker;
@class FuzzyMatcher;

/// 候选词结构
@interface CandidateWord : NSObject
@property (nonatomic, copy) NSString *word;       // 候选词文本
@property (nonatomic, copy) NSString *pinyin;     // 对应拼音
@property (nonatomic, assign) NSInteger frequency; // 词频
@property (nonatomic, assign) NSInteger source;    // 来源
@property (nonatomic, assign) double score;        // 综合得分
@end

@interface PinyinEngine : NSObject

/// 拼音解析器
@property (nonatomic, strong) PinyinParser *parser;

/// 候选词排序器
@property (nonatomic, strong) CandidateRanker *ranker;

/// 模糊音匹配器
@property (nonatomic, strong) FuzzyMatcher *fuzzyMatcher;

/// 是否启用模糊音
@property (nonatomic, assign) BOOL fuzzyEnabled;

/// 初始化引擎
- (instancetype)init;

/// 获取候选词列表
- (NSArray<NSString *> *)getCandidatesForPinyin:(NSString *)pinyin
                               dictionaryManager:(DictionaryManager *)dictManager;

/// 获取所有候选词（包含详细信息的 CandidateWord 对象）
- (NSArray<CandidateWord *> *)getCandidateWordsForPinyin:(NSString *)pinyin
                                        dictionaryManager:(DictionaryManager *)dictManager;

/// 记录用户选择（用于词频学习）
- (void)recordUserSelection:(NSString *)pinyin word:(NSString *)word;

/// 将拼音字符串拆分为合法拼音组合
- (NSArray<NSArray<NSString *> *> *)splitPinyin:(NSString *)pinyin;

@end
