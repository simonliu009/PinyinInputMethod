/*
 * PinyinInputMethod - macOS 拼音输入法
 * SogouSCelParserTests.m - 搜狗词库解析器单元测试
 */

#import <XCTest/XCTest.h>
#import "SogouSCelParser.h"

@interface SogouSCelParserTests : XCTestCase
@property (nonatomic, strong) SogouSCelParser *parser;
@end

@implementation SogouSCelParserTests

- (void)setUp {
    _parser = [[SogouSCelParser alloc] init];
}

#pragma mark - 文件验证测试

- (void)testParseNonExistentFile {
    NSArray *result = [_parser parseFile:@"/nonexistent/path/file.scel"];
    XCTAssertNil(result, @"不存在的文件应返回 nil");
}

- (void)testParseEmptyFile {
    // 创建临时空文件
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_empty.scel"];
    [@"" writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *result = [_parser parseFile:tempPath];
    XCTAssertNil(result, @"空文件应返回 nil");
    
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

- (void)testParseInvalidFile {
    // 创建无效内容的临时文件
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_invalid.scel"];
    NSData *randomData = [@"This is not a valid scel file" dataUsingEncoding:NSUTF8StringEncoding];
    [randomData writeToFile:tempPath atomically:YES];
    
    NSArray *result = [_parser parseFile:tempPath];
    // 无效文件可能返回 nil 或空数组
    XCTAssertTrue(result == nil || result.count == 0, @"无效文件应返回 nil 或空数组");
    
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

#pragma mark - 文件信息测试

- (void)testGetFileInfoNonExistent {
    NSDictionary *info = [_parser getFileInfo:@"/nonexistent/file.scel"];
    XCTAssertNil(info, @"不存在的文件应返回 nil");
}

#pragma mark - 进度回调测试

- (void)testProgressCallbackWithInvalidFile {
    __block BOOL progressCalled = NO;
    
    [_parser parseFile:@"/nonexistent/file.scel"
         progressHandler:^(float progress, NSInteger count) {
             progressCalled = YES;
         }];
    
    // 无效文件不应触发进度回调
    XCTAssertFalse(progressCalled, @"无效文件不应触发进度回调");
}

@end
