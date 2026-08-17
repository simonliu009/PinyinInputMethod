/*
 * PinyinInputMethod - macOS 拼音输入�?
 * StringHelper.m - 字符串工具实�?
 */

#import "StringHelper.h"

@implementation StringHelper

+ (NSString *)lowercaseString:(NSString *)str {
    if (!str) return @"";
    return [str lowercaseString];
}

+ (NSString *)trimmedString:(NSString *)str {
    if (!str) return @"";
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (BOOL)isAlphaOnly:(NSString *)str {
    if (!str || str.length == 0) return NO;
    
    NSCharacterSet *nonAlpha = [[NSCharacterSet letterCharacterSet] invertedSet];
    return [str rangeOfCharacterFromSet:nonAlpha].location == NSNotFound;
}

+ (BOOL)isChineseOnly:(NSString *)str {
    if (!str || str.length == 0) return NO;
    
    for (NSUInteger i = 0; i < str.length; i++) {
        unichar ch = [str characterAtIndex:i];
        // CJK 统一汉字范围
        if (ch < 0x4E00 || ch > 0x9FFF) {
            // 也包含扩展区
            if (ch < 0x3400 || ch > 0x4DBF) {
                return NO;
            }
        }
    }
    return YES;
}

+ (NSUInteger)utf8Length:(NSString *)str {
    if (!str) return 0;
    return [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringFromUTF16LEData:(NSData *)data {
    if (!data || data.length == 0) return @"";
    return [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
}

+ (NSData *)utf16LEDataFromString:(NSString *)string {
    if (!string) return [NSData data];
    return [string dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
}

+ (NSString *)substring:(NSString *)str maxLength:(NSUInteger)maxLength {
    if (!str) return @"";
    if (str.length <= maxLength) return str;
    return [str substringToIndex:maxLength];
}

+ (BOOL)string:(NSString *)str startsWith:(NSString *)prefix ignoreCase:(BOOL)ignoreCase {
    if (!str || !prefix) return NO;
    if (prefix.length > str.length) return NO;
    
    if (ignoreCase) {
        return [[str lowercaseString] hasPrefix:[prefix lowercaseString]];
    }
    return [str hasPrefix:prefix];
}

@end
