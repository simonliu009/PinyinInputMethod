/*
 * PinyinInputMethod - macOS 拼音输入法
 * CandidateRanker.m - 候选词排序算法实现
 *
 * 排序策略：词频权重 + 用户习惯 + 词组长度优先 + 拼音匹配度
 */

#import "CandidateRanker.h"
#import "PinyinEngine.h"  // for CandidateWord

@implementation CandidateRanker

// 权重常量
static const double kFrequencyWeight = 0.4;    // 词频权重
static const double kLengthWeight    = 0.2;    // 词长权重
static const double kMatchWeight     = 0.3;    // 匹配度权重
static const double kUserWeight      = 0.1;    // 用户习惯权重

- (double)calculateScoreForCandidate:(CandidateWord *)candidate
                         inputPinyin:(NSString *)inputPinyin
                         pinyinParts:(NSArray<NSString *> *)pinyinParts
{
    double score = 0.0;
    
    // 1. 词频得分（归一化到 0-1）
    double freqScore = log10(candidate.frequency + 1) / 6.0;  // 假设最大词频约 100万
    score += freqScore * kFrequencyWeight;
    
    // 2. 词组长度得分（更长的词组通常更精确）
    double lengthScore = 0.0;
    if (pinyinParts.count > 0) {
        // 如果候选词的字数与拼音音节数匹配，给予加分
        NSInteger wordLength = candidate.word.length;
        NSInteger pinyinCount = pinyinParts.count;
        
        if (wordLength == pinyinCount) {
            lengthScore = 1.0;  // 完美匹配
        } else if (wordLength == 1 && pinyinCount == 1) {
            lengthScore = 0.5;  // 单字匹配
        } else {
            lengthScore = 0.3;  // 部分匹配
        }
    }
    score += lengthScore * kLengthWeight;
    
    // 3. 拼音匹配度得分
    double matchScore = 0.0;
    if (candidate.pinyin.length > 0) {
        // 精确拼音匹配
        NSString *candidatePinyin = [candidate.pinyin lowercaseString];
        NSString *inputLower = [inputPinyin lowercaseString];
        
        if ([candidatePinyin isEqualToString:inputLower]) {
            matchScore = 1.0;
        } else if ([candidatePinyin hasPrefix:inputLower]) {
            matchScore = 0.8;
        } else if ([inputLower hasPrefix:candidatePinyin]) {
            matchScore = 0.6;
        } else {
            // 计算编辑距离相似度
            matchScore = [self similarityBetween:candidatePinyin and:inputLower];
        }
    }
    score += matchScore * kMatchWeight;
    
    // 4. 用户习惯加分（由外部设置，这里使用 source 字段间接判断）
    if (candidate.source == 2) {  // 用户自定义词
        score += 0.5 * kUserWeight;
    }
    
    return score;
}

- (NSArray<CandidateWord *> *)rankCandidates:(NSArray<CandidateWord *> *)candidates {
    if (candidates.count == 0) return @[];
    
    // 去重（相同词语只保留最高分的）
    NSMutableDictionary<NSString *, CandidateWord *> *uniqueMap = [NSMutableDictionary dictionary];
    for (CandidateWord *cw in candidates) {
        CandidateWord *existing = uniqueMap[cw.word];
        if (!existing || cw.score > existing.score) {
            uniqueMap[cw.word] = cw;
        }
    }
    
    // 按得分降序排序
    NSArray *sorted = [[uniqueMap allValues] sortedArrayUsingComparator:
        ^NSComparisonResult(CandidateWord *a, CandidateWord *b) {
            if (a.score > b.score) return NSOrderedAscending;
            if (a.score < b.score) return NSOrderedDescending;
            // 得分相同时，词频高的优先
            if (a.frequency > b.frequency) return NSOrderedAscending;
            if (a.frequency < b.frequency) return NSOrderedDescending;
            return NSOrderedSame;
        }];
    
    return sorted;
}

#pragma mark - 辅助方法

/// 计算两个字符串的相似度（基于编辑距离）
- (double)similarityBetween:(NSString *)s1 and:(NSString *)s2 {
    NSInteger len1 = s1.length;
    NSInteger len2 = s2.length;
    
    if (len1 == 0 && len2 == 0) return 1.0;
    if (len1 == 0 || len2 == 0) return 0.0;
    
    // 简化的编辑距离计算
    NSInteger maxLen = MAX(len1, len2);
    NSInteger distance = [self editDistance:s1 s2:s2];
    
    return 1.0 - ((double)distance / (double)maxLen);
}

/// 计算编辑距离（Levenshtein Distance）
- (NSInteger)editDistance:(NSString *)s1 s2:(NSString *)s2 {
    NSInteger len1 = s1.length;
    NSInteger len2 = s2.length;
    
    // 使用一维数组优化空间
    NSMutableArray<NSNumber *> *prev = [NSMutableArray arrayWithCapacity:len2 + 1];
    NSMutableArray<NSNumber *> *curr = [NSMutableArray arrayWithCapacity:len2 + 1];
    
    for (NSInteger j = 0; j <= len2; j++) {
        prev[j] = @(j);
    }
    
    for (NSInteger i = 1; i <= len1; i++) {
        curr[0] = @(i);
        unichar c1 = [s1 characterAtIndex:i - 1];
        
        for (NSInteger j = 1; j <= len2; j++) {
            unichar c2 = [s2 characterAtIndex:j - 1];
            
            NSInteger cost = (c1 == c2) ? 0 : 1;
            
            NSInteger insert = [curr[j - 1] integerValue] + 1;
            NSInteger delete = [prev[j] integerValue] + 1;
            NSInteger replace = [prev[j - 1] integerValue] + cost;
            
            curr[j] = @(MIN(MIN(insert, delete), replace));
        }
        
        [prev setArray:curr];
    }
    
    return [prev[len2] integerValue];
}

@end
