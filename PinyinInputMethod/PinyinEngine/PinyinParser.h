/*
 * PinyinInputMethod - macOS 拼音输入法
 * PinyinParser.h - 拼音解析器
 *
 * 负责将字母序列拆分为合法拼音组合，支持声母/韵母/整体认读音节
 */

#import <Foundation/Foundation.h>

@interface PinyinParser : NSObject

/// 所有合法拼音音节集合
@property (nonatomic, strong, readonly) NSSet<NSString *> *validPinyins;

/// 所有合法声母集合
@property (nonatomic, strong, readonly) NSSet<NSString *> *initials;

/// 初始化解析器，加载拼音表
- (instancetype)init;

/// 将连续拼音字符串拆分为所有合法的拼音组合
/// 例如 "nihao" -> [["ni", "hao"], ["n", "i", "h", "ao"], ...]
/// 返回按优先级排序的拆分方案列表
- (NSArray<NSArray<NSString *> *> *)splitPinyinString:(NSString *)input;

/// 检查给定字符串是否为合法拼音
- (BOOL)isValidPinyin:(NSString *)pinyin;

/// 获取拼音的声母部分
- (NSString *)getInitial:(NSString *)pinyin;

/// 获取拼音的韵母部分
- (NSString *)getFinal:(NSString *)pinyin;

@end
