/*
 * PinyinInputMethod - macOS 拼音输入�?
 * StringHelper.h - 字符串工�?
 */

#import <Foundation/Foundation.h>

@interface StringHelper : NSObject

/// 将字符串转为小写
+ (NSString *)lowercaseString:(NSString *)str;

/// 去除字符串两端空�?
+ (NSString *)trimmedString:(NSString *)str;

/// 检查字符串是否只包含字�?
+ (BOOL)isAlphaOnly:(NSString *)str;

/// 检查字符串是否只包含中�?
+ (BOOL)isChineseOnly:(NSString *)str;

/// 计算字符串的 UTF-8 字节长度
+ (NSUInteger)utf8Length:(NSString *)str;

/// �?UTF-16LE 数据转为 NSString
+ (NSString *)stringFromUTF16LEData:(NSData *)data;

/// �?NSString 转为 UTF-16LE 数据
+ (NSData *)utf16LEDataFromString:(NSString *)string;

/// 安全截取字符串前 N 个字�?
+ (NSString *)substring:(NSString *)str maxLength:(NSUInteger)maxLength;

/// 检查字符串是否以指定前缀开头（忽略大小写）
+ (BOOL)string:(NSString *)str startsWith:(NSString *)prefix ignoreCase:(BOOL)ignoreCase;

@end
