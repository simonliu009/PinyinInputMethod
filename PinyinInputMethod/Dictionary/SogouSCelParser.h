/*
 * PinyinInputMethod - macOS 拼音输入法
 * SogouSCelParser.h - 搜狗 .scel 文件解析器
 *
 * 解析搜狗输入法的自定义词库文件（.scel 格式）
 * 参考格式规范：
 *   - 文件头：0x40 字节
 *   - 拼音表：从偏移 0x120 开始
 *   - 词条区：从偏移 0x2620（或文件头指定）开始
 *   - 编码：UTF-16LE
 */

#import <Foundation/Foundation.h>

/// 解析出的词条结构
@interface SogouWordEntry : NSObject
@property (nonatomic, copy) NSString *word;       // 词语
@property (nonatomic, copy) NSString *pinyin;     // 拼音（空格分隔）
@property (nonatomic, assign) NSInteger frequency; // 词频
@property (nonatomic, copy) NSString *comment;    // 注释（如果有）
@end

@interface SogouSCelParser : NSObject

/// 解析 .scel 文件
/// @param filePath .scel 文件路径
/// @param progressHandler 进度回调（0.0 - 1.0）
/// @return 解析出的词条数组，失败返回 nil
- (NSArray<NSDictionary *> *)parseFile:(NSString *)filePath
                         progressHandler:(void(^)(float progress, NSInteger count))progressHandler;

/// 解析 .scel 文件（简化版，无进度回调）
- (NSArray<NSDictionary *> *)parseFile:(NSString *)filePath;

/// 获取 .scel 文件信息（名称、描述、词条数等）
- (NSDictionary *)getFileInfo:(NSString *)filePath;

@end
