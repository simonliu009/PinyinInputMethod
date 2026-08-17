/*
 * PinyinInputMethod - macOS 拼音输入法
 * FuzzyMatcher.h - 模糊音匹配器
 *
 * 处理常见模糊音情况，如 z/zh, c/ch, s/sh, n/l, f/h 等
 */

#import <Foundation/Foundation.h>

@interface FuzzyMatcher : NSObject

/// 模糊音映射表（可配置）
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSString *> *> *fuzzyMap;

/// 是否启用 z/zh 模糊
@property (nonatomic, assign) BOOL fuzzyZ_ZH;

/// 是否启用 c/ch 模糊
@property (nonatomic, assign) BOOL fuzzyC_CH;

/// 是否启用 s/sh 模糊
@property (nonatomic, assign) BOOL fuzzyS_SH;

/// 是否启用 n/l 模糊
@property (nonatomic, assign) BOOL fuzzyN_L;

/// 是否启用 f/h 模糊
@property (nonatomic, assign) BOOL fuzzyF_H;

/// 是否启用 an/ang 模糊
@property (nonatomic, assign) BOOL fuzzyAn_Ang;

/// 是否启用 en/eng 模糊
@property (nonatomic, assign) BOOL fuzzyEn_Eng;

/// 是否启用 in/ing 模糊
@property (nonatomic, assign) BOOL fuzzyIn_In;

/// 初始化
- (instancetype)init;

/// 获取给定拼音的模糊音替代列表
- (NSArray<NSString *> *)getFuzzyAlternativesForPinyin:(NSString *)pinyin;

/// 检查两个拼音是否属于模糊音对
- (BOOL)isFuzzyMatch:(NSString *)pinyin1 withPinyin:(NSString *)pinyin2;

@end
