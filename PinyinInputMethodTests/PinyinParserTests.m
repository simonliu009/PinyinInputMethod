/*
 * PinyinInputMethod - macOS 拼音输入法
 * PinyinParserTests.m - 拼音解析器单元测试
 */

#import <XCTest/XCTest.h>
#import "PinyinParser.h"

@interface PinyinParserTests : XCTestCase
@property (nonatomic, strong) PinyinParser *parser;
@end

@implementation PinyinParserTests

- (void)setUp {
    _parser = [[PinyinParser alloc] init];
}

#pragma mark - 拼音合法性测试

- (void)testValidPinyin {
    // 基本音节
    XCTAssertTrue([_parser isValidPinyin:@"ni"]);
    XCTAssertTrue([_parser isValidPinyin:@"hao"]);
    XCTAssertTrue([_parser isValidPinyin:@"zhong"]);
    XCTAssertTrue([_parser isValidPinyin:@"guo"]);
    
    // 整体认读
    XCTAssertTrue([_parser isValidPinyin:@"zhi"]);
    XCTAssertTrue([_parser isValidPinyin:@"chi"]);
    XCTAssertTrue([_parser isValidPinyin:@"shi"]);
    XCTAssertTrue([_parser isValidPinyin:@"ri"]);
    XCTAssertTrue([_parser isValidPinyin:@"zi"]);
    XCTAssertTrue([_parser isValidPinyin:@"ci"]);
    XCTAssertTrue([_parser isValidPinyin:@"si"]);
    
    // 特殊音节
    XCTAssertTrue([_parser isValidPinyin:@"a"]);
    XCTAssertTrue([_parser isValidPinyin:@"o"]);
    XCTAssertTrue([_parser isValidPinyin:@"e"]);
    XCTAssertTrue([_parser isValidPinyin:@"er"]);
    
    // 无效拼音
    XCTAssertFalse([_parser isValidPinyin:@""]);
    XCTAssertFalse([_parser isValidPinyin:@"nil"]);
    XCTAssertFalse([_parser isValidPinyin:@"abc"]);
    XCTAssertFalse([_parser isValidPinyin:@"xyz"]);
}

#pragma mark - 拼音拆分测试

- (void)testSplitSimple {
    // 简单拆分
    NSArray *splits = [_parser splitPinyinString:@"ni"];
    XCTAssertGreaterThan(splits.count, 0);
    
    // 第一个结果应该是 ["ni"]
    NSArray *firstSplit = splits.firstObject;
    XCTAssertEqual(firstSplit.count, 1);
    XCTAssertEqualObjects(firstSplit.firstObject, @"ni");
}

- (void)testSplitNihao {
    // "nihao" -> ["ni", "hao"]
    NSArray *splits = [_parser splitPinyinString:@"nihao"];
    XCTAssertGreaterThan(splits.count, 0);
    
    BOOL foundNihao = NO;
    for (NSArray *split in splits) {
        if (split.count == 2 &&
            [split[0] isEqualToString:@"ni"] &&
            [split[1] isEqualToString:@"hao"]) {
            foundNihao = YES;
            break;
        }
    }
    XCTAssertTrue(foundNihao, @"应该能找到 ni+hao 的拆分方案");
}

- (void)testSplitZhongguo {
    // "zhongguo" -> ["zhong", "guo"]
    NSArray *splits = [_parser splitPinyinString:@"zhongguo"];
    XCTAssertGreaterThan(splits.count, 0);
    
    BOOL found = NO;
    for (NSArray *split in splits) {
        if (split.count == 2 &&
            [split[0] isEqualToString:@"zhong"] &&
            [split[1] isEqualToString:@"guo"]) {
            found = YES;
            break;
        }
    }
    XCTAssertTrue(found, @"应该能找到 zhong+guo 的拆分方案");
}

- (void)testSplitEmpty {
    NSArray *splits = [_parser splitPinyinString:@""];
    XCTAssertEqual(splits.count, 0);
}

- (void)testSplitSingleChar {
    // 单个字母 "a"
    NSArray *splits = [_parser splitPinyinString:@"a"];
    XCTAssertEqual(splits.count, 1);
    XCTAssertEqualObjects(splits.firstObject.firstObject, @"a");
}

- (void)testSplitAmbiguous {
    // "xian" 可以拆分为 "xi" + "an" 或 "xian"
    NSArray *splits = [_parser splitPinyinString:@"xian"];
    XCTAssertGreaterThan(splits.count, 0);
    
    // 应该包含 "xian" 作为单个音节的方案
    BOOL hasSingle = NO;
    for (NSArray *split in splits) {
        if (split.count == 1 && [split.firstObject isEqualToString:@"xian"]) {
            hasSingle = YES;
            break;
        }
    }
    XCTAssertTrue(hasSingle, @"'xian' 应该可以作为单个音节");
}

#pragma mark - 声母韵母测试

- (void)testGetInitial {
    XCTAssertEqualObjects([_parser getInitial:@"ni"], @"n");
    XCTAssertEqualObjects([_parser getInitial:@"zhong"], @"zh");
    XCTAssertEqualObjects([_parser getInitial:@"chi"], @"ch");
    XCTAssertEqualObjects([_parser getInitial:@"shi"], @"sh");
    XCTAssertEqualObjects([_parser getInitial:@"a"], @"");
    XCTAssertEqualObjects([_parser getInitial:@"er"], @"");
}

- (void)testGetFinal {
    XCTAssertEqualObjects([_parser getFinal:@"ni"], @"i");
    XCTAssertEqualObjects([_parser getFinal:@"zhong"], @"ong");
    XCTAssertEqualObjects([_parser getFinal:@"chi"], @"i");
    XCTAssertEqualObjects([_parser getFinal:@"a"], @"a");
    XCTAssertEqualObjects([_parser getFinal:@"er"], @"er");
}

#pragma mark - 拼音表完整性

- (void)testPinyinTableNotEmpty {
    XCTAssertGreaterThan(_parser.validPinyins.count, 300);
}

- (void)testPinyinTableContainsCommon {
    NSSet *pinyins = _parser.validPinyins;
    XCTAssertTrue([pinyins containsObject:@"a"]);
    XCTAssertTrue([pinyins containsObject:@"ba"]);
    XCTAssertTrue([pinyins containsObject:@"zhong"]);
    XCTAssertTrue([pinyins containsObject:@"zhuang"]);
}

@end
