/*
 * PinyinInputMethod - macOS 拼音输入法
 * CandidateRanker.h - 候选词排序算法
 */

#import <Foundation/Foundation.h>

@class CandidateWord;

@interface CandidateRanker : NSObject

/// 计算候选词的综合得分
- (double)calculateScoreForCandidate:(CandidateWord *)candidate
                         inputPinyin:(NSString *)inputPinyin
                         pinyinParts:(NSArray<NSString *> *)pinyinParts;

/// 对候选词列表进行排序（返回去重后的排序结果）
- (NSArray<CandidateWord *> *)rankCandidates:(NSArray<CandidateWord *> *)candidates;

@end
