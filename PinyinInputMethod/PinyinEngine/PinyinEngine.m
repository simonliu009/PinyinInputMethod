/*
 * PinyinInputMethod - macOS 拼音输入�?
 * PinyinEngine.m - 拼音引擎主类实现
 */

#import "PinyinEngine.h"
#import "PinyinParser.h"
#import "CandidateRanker.h"
#import "FuzzyMatcher.h"
#import "DictionaryManager.h"
#import "ConfigManager.h"

#pragma mark - CandidateWord 实现

@implementation CandidateWord

- (NSString *)description {
    return [NSString stringWithFormat:@"<Candidate: %@ (%@) freq=%ld score=%.2f>",
            _word, _pinyin, (long)_frequency, _score];
}

@end

#pragma mark - PinyinEngine 实现

@implementation PinyinEngine

- (instancetype)init {
    self = [super init];
    if (self) {
        _parser = [[PinyinParser alloc] init];
        _ranker = [[CandidateRanker alloc] init];
        _fuzzyMatcher = [[FuzzyMatcher alloc] init];
        
        // 从配置中读取模糊音设�?
        _fuzzyEnabled = [[ConfigManager sharedManager] boolForKey:@"fuzzyEnabled" defaultValue:NO];
        
        NSLog(@"[PinyinEngine] 拼音引擎已初始化，模糊音: %@", _fuzzyEnabled ? @"开�? : @"关闭");
    }
    return self;
}

#pragma mark - 候选词获取

- (NSArray<NSString *> *)getCandidatesForPinyin:(NSString *)pinyin
                               dictionaryManager:(DictionaryManager *)dictManager
{
    NSArray<CandidateWord *> *candidates = [self getCandidateWordsForPinyin:pinyin
                                                          dictionaryManager:dictManager];
    
    // 只返回词语字符串
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:candidates.count];
    for (CandidateWord *cw in candidates) {
        if (![result containsObject:cw.word]) {
            [result addObject:cw.word];
        }
    }
    return result;
}

- (NSArray<CandidateWord *> *)getCandidateWordsForPinyin:(NSString *)pinyin
                                        dictionaryManager:(DictionaryManager *)dictManager
{
    if (pinyin.length == 0) return @[];
    
    NSMutableArray<CandidateWord *> *allCandidates = [NSMutableArray array];
    
    // 1. 获取所有合法的拼音拆分方案
    NSArray<NSArray<NSString *> *> *splitResults = [self splitPinyin:pinyin];
    
    // 2. 对每种拆分方案，从词库中查找对应汉字
    for (NSArray<NSString *> *pinyinParts in splitResults) {
        NSString *joinedPinyin = [pinyinParts componentsJoinedByString:@" "];
        
        // 2a. 查找完整拼音组合对应的词�?
        NSArray *words = [dictManager queryWordsWithPinyin:joinedPinyin];
        for (NSDictionary *wordDict in words) {
            CandidateWord *cw = [[CandidateWord alloc] init];
            cw.word = wordDict[@"word"];
            cw.pinyin = wordDict[@"pinyin"];
            cw.frequency = [wordDict[@"frequency"] integerValue];
            cw.source = [wordDict[@"source"] integerValue];
            cw.score = [_ranker calculateScoreForCandidate:cw
                                                inputPinyin:pinyin
                                               pinyinParts:pinyinParts];
            [allCandidates addObject:cw];
        }
        
        // 2b. 单字查找（每个拼音音节对应的单字�?
        if (pinyinParts.count > 1) {
            for (NSString *singlePinyin in pinyinParts) {
                NSArray *singleChars = [dictManager queryWordsWithPinyin:singlePinyin];
                for (NSDictionary *wordDict in singleChars) {
                    NSString *word = wordDict[@"word"];
                    // 只添加单字候�?
                    if (word.length <= 2) {  // 允许单字和少量双�?
                        CandidateWord *cw = [[CandidateWord alloc] init];
                        cw.word = word;
                        cw.pinyin = wordDict[@"pinyin"];
                        cw.frequency = [wordDict[@"frequency"] integerValue] / 2; // 降低单字优先�?
                        cw.source = [wordDict[@"source"] integerValue];
                        cw.score = [_ranker calculateScoreForCandidate:cw
                                                            inputPinyin:pinyin
                                                           pinyinParts:pinyinParts] * 0.5;
                        [allCandidates addObject:cw];
                    }
                }
            }
        }
    }
    
    // 3. 如果启用了模糊音，添加模糊音匹配结果
    if (_fuzzyEnabled) {
        NSArray *fuzzyPinyins = [_fuzzyMatcher getFuzzyAlternativesForPinyin:pinyin];
        for (NSString *fuzzyPy in fuzzyPinyins) {
            NSArray *fuzzyWords = [dictManager queryWordsWithPinyin:fuzzyPy];
            for (NSDictionary *wordDict in fuzzyWords) {
                CandidateWord *cw = [[CandidateWord alloc] init];
                cw.word = wordDict[@"word"];
                cw.pinyin = wordDict[@"pinyin"];
                cw.frequency = [wordDict[@"frequency"] integerValue];
                cw.source = [wordDict[@"source"] integerValue];
                cw.score = [_ranker calculateScoreForCandidate:cw
                                                    inputPinyin:pinyin
                                                   pinyinParts:@[fuzzyPy]] * 0.7; // 模糊音降低得�?
                [allCandidates addObject:cw];
            }
        }
    }
    
    // 4. 去重并按得分排序
    allCandidates = (NSMutableArray *)[_ranker rankCandidates:allCandidates];
    
    return allCandidates;
}

#pragma mark - 拼音拆分

- (NSArray<NSArray<NSString *> *> *)splitPinyin:(NSString *)pinyin {
    return [_parser splitPinyinString:pinyin];
}

#pragma mark - 用户习惯学习

- (void)recordUserSelection:(NSString *)pinyin word:(NSString *)word {
    if (!pinyin || !word) return;
    
    // 记录到数据库
    [[DictionaryManager sharedManager] recordUserHabitWithPinyin:pinyin word:word];
    
    NSLog(@"[PinyinEngine] 记录用户选择: %@ -> %@", pinyin, word);
}

@end
