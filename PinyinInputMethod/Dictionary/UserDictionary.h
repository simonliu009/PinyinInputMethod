/*
 * PinyinInputMethod - macOS 拼音输入�?
 * UserDictionary.h - 用户自定义词�?
 *
 * 管理用户自造词、自定义短语等功�?
 */

#import <Foundation/Foundation.h>

/// 自定义短语条�?
@interface CustomPhrase : NSObject
@property (nonatomic, copy) NSString *trigger;    // 触发键（�?"rq" 代表日期�?
@property (nonatomic, copy) NSString *phrase;     // 展开的短语内�?
@property (nonatomic, copy) NSString *comment;    // 备注
@property (nonatomic, assign) NSInteger priority; // 优先�?
@end

@interface UserDictionary : NSObject

/// 添加用户�?
- (BOOL)addWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 删除用户�?
- (BOOL)removeWord:(NSString *)word pinyin:(NSString *)pinyin;

/// 查询用户�?
- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin;

/// 添加自定义短�?
- (BOOL)addCustomPhrase:(CustomPhrase *)phrase;

/// 删除自定义短�?
- (BOOL)removeCustomPhraseWithTrigger:(NSString *)trigger;

/// 获取所有自定义短语
- (NSArray<CustomPhrase *> *)allCustomPhrases;

/// 检查触发键是否匹配自定义短�?
- (NSString *)expandCustomPhrase:(NSString *)trigger;

/// 导出用户词库
- (NSString *)exportAsText;

/// 导入用户词库
- (BOOL)importFromText:(NSString *)text;

@end
