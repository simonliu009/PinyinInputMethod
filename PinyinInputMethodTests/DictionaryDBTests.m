/*
 * PinyinInputMethod - macOS 拼音输入法
 * DictionaryDBTests.m - 数据库操作单元测试
 */

#import <XCTest/XCTest.h>
#import "DictionaryDB.h"

@interface DictionaryDBTests : XCTestCase
@property (nonatomic, strong) DictionaryDB *db;
@property (nonatomic, copy) NSString *testDBPath;
@end

@implementation DictionaryDBTests

- (void)setUp {
    // 创建临时数据库
    self.testDBPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
        [NSString stringWithFormat:@"test_dict_%@.db", [[NSUUID UUID] UUIDString]]];
    self.db = [[DictionaryDB alloc] initWithPath:self.testDBPath];
}

- (void)tearDown {
    [self.db close];
    [[NSFileManager defaultManager] removeItemAtPath:self.testDBPath error:nil];
}

#pragma mark - 插入测试

- (void)testInsertWord {
    BOOL result = [self.db insertWord:@"测试" pinyin:@"ce shi" frequency:1000 source:0];
    XCTAssertTrue(result, @"插入应成功");
}

- (void)testBatchInsert {
    NSArray *words = @[
        @{@"word": @"我们", @"pinyin": @"wo men", @"frequency": @450000, @"source": @0},
        @{@"word": @"中国", @"pinyin": @"zhong guo", @"frequency": @440000, @"source": @0},
        @{@"word": @"可以", @"pinyin": @"ke yi", @"frequency": @430000, @"source": @0},
    ];
    
    BOOL result = [self.db insertWords:words];
    XCTAssertTrue(result, @"批量插入应成功");
    
    XCTAssertEqual([self.db totalWordCount], 3, @"应该有 3 条词条");
}

#pragma mark - 查询测试

- (void)testQueryByPinyin {
    [self.db insertWord:@"我们" pinyin:@"wo men" frequency:450000 source:0];
    [self.db insertWord:@"我的" pinyin:@"wo de" frequency:400000 source:0];
    
    NSArray *results = [self.db queryWordsWithPinyin:@"wo men"];
    XCTAssertEqual(results.count, 1, @"精确匹配应返回 1 条");
    XCTAssertEqualObjects(results.firstObject[@"word"], @"我们");
}

- (void)testQueryByPrefix {
    [self.db insertWord:@"我们" pinyin:@"wo men" frequency:450000 source:0];
    [self.db insertWord:@"我的" pinyin:@"wo de" frequency:400000 source:0];
    [self.db insertWord:@"问题" pinyin:@"wen ti" frequency:310000 source:0];
    
    NSArray *results = [self.db queryWordsWithPinyinPrefix:@"wo" limit:10];
    XCTAssertEqual(results.count, 2, @"前缀匹配应返回 2 条");
}

- (void)testQueryOrderByFrequency {
    [self.db insertWord:@"低词频" pinyin:@"di" frequency:100 source:0];
    [self.db insertWord:@"高词频" pinyin:@"di" frequency:10000 source:0];
    [self.db insertWord:@"中词频" pinyin:@"di" frequency:1000 source:0];
    
    NSArray *results = [self.db queryWordsWithPinyin:@"di"];
    XCTAssertEqual(results.count, 3);
    
    // 应按词频降序排列
    NSInteger prev = NSIntegerMax;
    for (NSDictionary *r in results) {
        NSInteger freq = [r[@"frequency"] integerValue];
        XCTAssertLessThanOrEqual(freq, prev, @"结果应按词频降序");
        prev = freq;
    }
}

#pragma mark - 删除测试

- (void)testDeleteWord {
    [self.db insertWord:@"删除测试" pinyin:@"ce shi" frequency:100 source:0];
    XCTAssertEqual([self.db totalWordCount], 1);
    
    [self.db deleteWord:@"删除测试" pinyin:@"ce shi"];
    XCTAssertEqual([self.db totalWordCount], 0, @"删除后应为 0 条");
}

- (void)testDeleteBySource {
    [self.db insertWord:@"基础" pinyin:@"ji chu" frequency:100 source:0];
    [self.db insertWord:@"搜狗" pinyin:@"sou gou" frequency:100 source:1];
    [self.db insertWord:@"用户" pinyin:@"yong hu" frequency:100 source:2];
    
    XCTAssertEqual([self.db totalWordCount], 3);
    
    [self.db deleteWordsWithSource:1];
    XCTAssertEqual([self.db totalWordCount], 2, @"删除搜狗来源后应剩 2 条");
    XCTAssertEqual([self.db wordCountForSource:1], 0);
}

#pragma mark - 用户习惯测试

- (void)testRecordUserHabit {
    BOOL result = [self.db recordUserHabit:@"ni hao" word:@"你好"];
    XCTAssertTrue(result);
    
    NSArray *habits = [self.db getUserHabitsForPinyin:@"ni hao" limit:10];
    XCTAssertEqual(habits.count, 1);
    XCTAssertEqualObjects(habits.firstObject[@"word"], @"你好");
}

- (void)testUserHabitHitCount {
    [self.db recordUserHabit:@"ni hao" word:@"你好"];
    [self.db recordUserHabit:@"ni hao" word:@"你好"];
    [self.db recordUserHabit:@"ni hao" word:@"你好"];
    
    NSArray *habits = [self.db getUserHabitsForPinyin:@"ni hao" limit:10];
    XCTAssertEqual(habits.count, 1);
    XCTAssertEqual([habits.firstObject[@"hit_count"] integerValue], 3, @"点击次数应为 3");
}

#pragma mark - 统计测试

- (void)testTotalWordCount {
    XCTAssertEqual([self.db totalWordCount], 0, @"初始应为 0");
    
    [self.db insertWord:@"测试" pinyin:@"ce shi" frequency:100 source:0];
    XCTAssertEqual([self.db totalWordCount], 1);
}

- (void)testWordCountBySource {
    [self.db insertWord:@"基础" pinyin:@"ji chu" frequency:100 source:0];
    [self.db insertWord:@"搜狗1" pinyin:@"sou gou" frequency:100 source:1];
    [self.db insertWord:@"搜狗2" pinyin:@"ci ku" frequency:100 source:1];
    
    XCTAssertEqual([self.db wordCountForSource:0], 1);
    XCTAssertEqual([self.db wordCountForSource:1], 2);
    XCTAssertEqual([self.db wordCountForSource:2], 0);
}

@end
