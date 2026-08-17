/*
 * PinyinInputMethod - macOS 拼音输入法
 * SogouSCelParser.m - 搜狗 .scel 文件解析器实现
 *
 * 搜狗 .scel 文件格式：
 * ┌─────────────────────────────┐
 * │ 文件头 (0x40 bytes)         │  包含魔法数字、版本号等
 * ├─────────────────────────────┤
 * │ 信息区 (名称/作者/描述等)    │  UTF-16LE 编码
 * ├─────────────────────────────┤
 * │ 拼音表 (从 0x120 开始)      │  拼音索引表
 * ├─────────────────────────────┤
 * │ 词条区 (从 0x2620 开始)     │  实际词组数据
 * └─────────────────────────────┘
 */

#import "SogouSCelParser.h"

@implementation SogouWordEntry

- (NSString *)description {
    return [NSString stringWithFormat:@"<SogouWord: %@ (%@) freq=%ld>",
            _word, _pinyin, (long)_frequency];
}

@end

@implementation SogouSCelParser

// .scel 文件关键偏移
static const NSUInteger kHeaderSize = 0x40;        // 文件头大小
static const NSUInteger kPinyinTableOffset = 0x120; // 拼音表起始偏移
static const NSUInteger kWordsOffset = 0x2620;      // 词条区起始偏移（默认值）

// 魔法数字
static const uint32_t kMagicNumber = 0x00004D43;    // "MC\0\0"

#pragma mark - 公开接口

- (NSArray<NSDictionary *> *)parseFile:(NSString *)filePath {
    return [self parseFile:filePath progressHandler:nil];
}

- (NSArray<NSDictionary *> *)parseFile:(NSString *)filePath
                         progressHandler:(void(^)(float progress, NSInteger count))progressHandler
{
    // 读取文件数据
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData || fileData.length < kHeaderSize) {
        NSLog(@"[SogouSCel] 无法读取文件或文件太小: %@", filePath);
        return nil;
    }
    
    const uint8_t *bytes = fileData.bytes;
    NSUInteger fileLen = fileData.length;
    
    // 1. 验证文件头
    if (![self validateHeader:bytes length:fileLen]) {
        return nil;
    }
    
    // 2. 解析拼音索引表
    NSArray<NSString *> *pinyinTable = [self parsePinyinTable:bytes length:fileLen];
    if (!pinyinTable) {
        NSLog(@"[SogouSCel] 拼音表解析失败");
        return nil;
    }
    
    NSLog(@"[SogouSCel] 拼音表解析完成，共 %lu 个拼音", (unsigned long)pinyinTable.count);
    
    // 3. 确定词条区偏移
    NSUInteger wordsStartOffset = kWordsOffset;
    if (fileLen > 0x2624) {
        // 某些版本在 0x2620 处存储实际偏移
        uint32_t customOffset;
        memcpy(&customOffset, bytes + 0x2620, 4);
        if (customOffset > 0 && customOffset < fileLen) {
            wordsStartOffset = customOffset;
        }
    }
    
    // 4. 解析词条
    NSMutableArray<NSDictionary *> *words = [NSMutableArray array];
    NSUInteger offset = wordsStartOffset;
    NSInteger parsedCount = 0;
    
    while (offset + 4 < fileLen) {
        // 每个词条格式：
        // - 2 bytes: 拼音数量（每对拼音索引的个数）
        // - N * 2 bytes: 拼音索引（指向拼音表）
        // - 2 bytes: 词语字节长度
        // - N bytes: 词语数据（UTF-16LE）
        // - 2 bytes: 词条扩展信息长度（可能为 0）
        // - N bytes: 扩展信息（词频等）
        
        // 读取拼音数量
        if (offset + 2 > fileLen) break;
        uint16_t pinyinCount;
        memcpy(&pinyinCount, bytes + offset, 2);
        offset += 2;
        
        if (pinyinCount == 0 || pinyinCount > 50) {
            // 无效数据，尝试寻找下一个有效词条
            break;
        }
        
        // 读取拼音索引
        NSMutableArray<NSString *> *pinyinParts = [NSMutableArray arrayWithCapacity:pinyinCount];
        BOOL pinyinValid = YES;
        
        for (int i = 0; i < pinyinCount; i++) {
            if (offset + 2 > fileLen) {
                pinyinValid = NO;
                break;
            }
            uint16_t pinyinIndex;
            memcpy(&pinyinIndex, bytes + offset, 2);
            offset += 2;
            
            if (pinyinIndex < pinyinTable.count) {
                [pinyinParts addObject:pinyinTable[pinyinIndex]];
            } else {
                pinyinValid = NO;
                break;
            }
        }
        
        if (!pinyinValid) break;
        
        // 读取词语长度
        if (offset + 2 > fileLen) break;
        uint16_t wordByteLen;
        memcpy(&wordByteLen, bytes + offset, 2);
        offset += 2;
        
        if (wordByteLen == 0 || wordByteLen > 200 || offset + wordByteLen > fileLen) break;
        
        // 读取词语（UTF-16LE 编码）
        NSData *wordData = [NSData dataWithBytes:bytes + offset length:wordByteLen];
        NSString *word = [[NSString alloc] initWithData:wordData 
                                               encoding:NSUTF16LittleEndianStringEncoding];
        offset += wordByteLen;
        
        if (!word || word.length == 0) continue;
        
        // 读取扩展信息长度
        uint16_t extLen = 0;
        if (offset + 2 <= fileLen) {
            memcpy(&extLen, bytes + offset, 2);
            offset += 2;
            
            // 跳过扩展信息
            if (extLen > 0 && offset + extLen <= fileLen) {
                offset += extLen;
            }
        }
        
        // 构建词条字典
        NSString *pinyinStr = [pinyinParts componentsJoinedByString:@" "];
        
        // 估算词频（搜狗词库通常不直接存储词频，使用默认值）
        NSInteger frequency = 1000 + (pinyinCount * 100);
        
        [words addObject:@{
            @"word": word,
            @"pinyin": pinyinStr,
            @"frequency": @(frequency),
        }];
        
        parsedCount++;
        
        // 进度回调
        if (progressHandler && parsedCount % 100 == 0) {
            float progress = (float)(offset - wordsStartOffset) / (float)(fileLen - wordsStartOffset);
            progressHandler(MIN(progress, 1.0), parsedCount);
        }
    }
    
    NSLog(@"[SogouSCel] 词条解析完成，共 %lu 条", (unsigned long)words.count);
    
    if (progressHandler) {
        progressHandler(1.0, words.count);
    }
    
    return words;
}

- (NSDictionary *)getFileInfo:(NSString *)filePath {
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData || fileData.length < kHeaderSize) return nil;
    
    const uint8_t *bytes = fileData.bytes;
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    // 读取词库名称（在文件头后的信息区）
    // 名称通常位于偏移 0x130 处，长度在 0x128 处指定
    if (fileData.length > 0x130) {
        // 尝试读取名称长度
        uint32_t nameLen;
        memcpy(&nameLen, bytes + 0x128, 4);
        
        if (nameLen > 0 && nameLen < 1000 && 0x130 + nameLen <= fileData.length) {
            NSData *nameData = [NSData dataWithBytes:bytes + 0x130 length:nameLen];
            NSString *name = [[NSString alloc] initWithData:nameData 
                                                   encoding:NSUTF16LittleEndianStringEncoding];
            if (name) {
                info[@"name"] = name;
            }
        }
    }
    
    info[@"fileSize"] = @(fileData.length);
    
    return info;
}

#pragma mark - 文件头验证

- (BOOL)validateHeader:(const uint8_t *)bytes length:(NSUInteger)length {
    if (length < kHeaderSize) {
        NSLog(@"[SogouSCel] 文件太小，不是有效的 .scel 文件");
        return NO;
    }
    
    // 检查第一个字节是否为 'M' (0x4D) 或特定标识
    // 不同版本的 scel 可能有不同的头部标识
    // 常见标识：0x43, 0x4D 或其他
    
    // 搜狗 scel 文件通常以特定字节序列开头
    // 这里做宽松验证，主要检查文件大小和基本结构
    if (bytes[0] == 0x43 || bytes[0] == 0x4D || bytes[0] == 0x99) {
        return YES;
    }
    
    // 尝试通过拼音表区域验证
    // 拼音表区域应该包含有效的 UTF-16LE 拼音字符串
    if (length > kPinyinTableOffset + 10) {
        // 检查拼音表区域是否有看起来像拼音的文本
        return YES;  // 宽松验证
    }
    
    NSLog(@"[SogouSCel] 文件头验证失败");
    return NO;
}

#pragma mark - 拼音表解析

- (NSArray<NSString *> *)parsePinyinTable:(const uint8_t *)bytes length:(NSUInteger)length {
    if (length < kPinyinTableOffset + 4) return nil;
    
    NSMutableArray<NSString *> *pinyinTable = [NSMutableArray array];
    
    // 拼音表格式：
    // 在偏移 kPinyinTableOffset 处开始
    // 每个条目：2 字节索引 + 1 字节拼音长度 + N 字节拼音文本
    
    NSUInteger offset = kPinyinTableOffset;
    
    // 读取拼音表条目数（某些版本在此处存储）
    // 如果没有明确的条目数，则通过遍历来确定
    
    // 尝试读取条目数
    uint16_t entryCount = 0;
    if (offset + 2 <= length) {
        memcpy(&entryCount, bytes + offset, 2);
        offset += 2;
    }
    
    // 如果条目数看起来不合理，尝试另一种解析方式
    if (entryCount == 0 || entryCount > 1000) {
        // 直接遍历解析
        offset = kPinyinTableOffset;
        while (offset + 3 < length && offset < kWordsOffset) {
            // 读取拼音长度
            uint8_t pinyinLen = bytes[offset];
            offset += 1;
            
            if (pinyinLen == 0 || pinyinLen > 10) {
                // 可能到达了拼音表末尾
                if (pinyinTable.count > 0) break;
                continue;
            }
            
            if (offset + pinyinLen > length) break;
            
            // 读取拼音文本（ASCII）
            NSString *pinyin = [[NSString alloc] initWithBytes:bytes + offset
                                                        length:pinyinLen
                                                      encoding:NSASCIIStringEncoding];
            offset += pinyinLen;
            
            if (pinyin && pinyin.length > 0) {
                [pinyinTable addObject:[pinyin lowercaseString]];
            }
        }
    } else {
        // 按条目数解析
        for (int i = 0; i < entryCount; i++) {
            if (offset + 1 > length) break;
            
            uint8_t pinyinLen = bytes[offset];
            offset += 1;
            
            if (pinyinLen == 0 || pinyinLen > 10 || offset + pinyinLen > length) break;
            
            NSString *pinyin = [[NSString alloc] initWithBytes:bytes + offset
                                                        length:pinyinLen
                                                      encoding:NSASCIIStringEncoding];
            offset += pinyinLen;
            
            if (pinyin && pinyin.length > 0) {
                [pinyinTable addObject:[pinyin lowercaseString]];
            }
        }
    }
    
    // 如果解析失败，使用默认拼音表
    if (pinyinTable.count == 0) {
        NSLog(@"[SogouSCel] 警告：无法解析拼音表，使用默认表");
        pinyinTable = [self defaultPinyinTable];
    }
    
    return pinyinTable;
}

#pragma mark - 默认拼音表

- (NSArray<NSString *> *)defaultPinyinTable {
    // 标准拼音表（按搜狗索引顺序）
    return @[
        @"a", @"ai", @"an", @"ang", @"ao",
        @"ba", @"bai", @"ban", @"bang", @"bao",
        @"bei", @"ben", @"beng", @"bi", @"bian",
        @"biao", @"bie", @"bin", @"bing", @"bo",
        @"bu", @"ca", @"cai", @"can", @"cang",
        @"cao", @"ce", @"cen", @"ceng", @"ci",
        @"cong", @"cou", @"cu", @"cuan", @"cui",
        @"cun", @"cuo", @"cha", @"chai", @"chan",
        @"chang", @"chao", @"che", @"chen", @"cheng",
        @"chi", @"chong", @"chou", @"chu", @"chua",
        @"chuai", @"chuan", @"chuang", @"chui", @"chun",
        @"chuo", @"da", @"dai", @"dan", @"dang",
        @"dao", @"de", @"dei", @"deng", @"di",
        @"dian", @"diao", @"die", @"ding", @"diu",
        @"dong", @"dou", @"du", @"duan", @"dui",
        @"dun", @"duo", @"e", @"ei", @"en",
        @"eng", @"er", @"fa", @"fan", @"fang",
        @"fei", @"fen", @"feng", @"fo", @"fou",
        @"fu", @"ga", @"gai", @"gan", @"gang",
        @"gao", @"ge", @"gei", @"gen", @"geng",
        @"gong", @"gou", @"gu", @"gua", @"guai",
        @"guan", @"guang", @"gui", @"gun", @"guo",
        @"ha", @"hai", @"han", @"hang", @"hao",
        @"he", @"hei", @"hen", @"heng", @"hong",
        @"hou", @"hu", @"hua", @"huai", @"huan",
        @"huang", @"hui", @"hun", @"huo", @"ji",
        @"jia", @"jian", @"jiang", @"jiao", @"jie",
        @"jin", @"jing", @"jiong", @"jiu", @"ju",
        @"juan", @"jue", @"jun", @"ka", @"kai",
        @"kan", @"kang", @"kao", @"ke", @"ken",
        @"keng", @"kong", @"kou", @"ku", @"kua",
        @"kuai", @"kuan", @"kuang", @"kui", @"kun",
        @"kuo", @"la", @"lai", @"lan", @"lang",
        @"lao", @"le", @"lei", @"leng", @"li",
        @"lian", @"liang", @"liao", @"lie", @"lin",
        @"ling", @"liu", @"long", @"lou", @"lu",
        @"luan", @"lun", @"luo", @"lv", @"lve",
        @"ma", @"mai", @"man", @"mang", @"mao",
        @"me", @"mei", @"men", @"meng", @"mi",
        @"mian", @"miao", @"mie", @"min", @"ming",
        @"miu", @"mo", @"mou", @"mu", @"na",
        @"nai", @"nan", @"nang", @"nao", @"ne",
        @"nei", @"nen", @"neng", @"ni", @"nian",
        @"niang", @"niao", @"nie", @"nin", @"ning",
        @"niu", @"nong", @"nou", @"nu", @"nuan",
        @"nun", @"nuo", @"nv", @"nve", @"o",
        @"ou", @"pa", @"pai", @"pan", @"pang",
        @"pao", @"pei", @"pen", @"peng", @"pi",
        @"pian", @"piao", @"pie", @"pin", @"ping",
        @"po", @"pou", @"pu", @"qi", @"qia",
        @"qian", @"qiang", @"qiao", @"qie", @"qin",
        @"qing", @"qiong", @"qiu", @"qu", @"quan",
        @"que", @"qun", @"ran", @"rang", @"rao",
        @"re", @"ren", @"reng", @"ri", @"rong",
        @"rou", @"ru", @"rua", @"ruan", @"rui",
        @"run", @"ruo", @"sa", @"sai", @"san",
        @"sang", @"sao", @"se", @"sen", @"seng",
        @"si", @"song", @"sou", @"su", @"suan",
        @"sui", @"sun", @"suo", @"sha", @"shai",
        @"shan", @"shang", @"shao", @"she", @"shei",
        @"shen", @"sheng", @"shi", @"shou", @"shu",
        @"shua", @"shuai", @"shuan", @"shuang", @"shui",
        @"shun", @"shuo", @"ta", @"tai", @"tan",
        @"tang", @"tao", @"te", @"teng", @"ti",
        @"tian", @"tiao", @"tie", @"ting", @"tong",
        @"tou", @"tu", @"tuan", @"tui", @"tun",
        @"tuo", @"wa", @"wai", @"wan", @"wang",
        @"wei", @"wen", @"weng", @"wo", @"wu",
        @"xi", @"xia", @"xian", @"xiang", @"xiao",
        @"xie", @"xin", @"xing", @"xiong", @"xiu",
        @"xu", @"xuan", @"xue", @"xun", @"ya",
        @"yan", @"yang", @"yao", @"ye", @"yi",
        @"yin", @"ying", @"yo", @"yong", @"you",
        @"yu", @"yuan", @"yue", @"yun", @"za",
        @"zai", @"zan", @"zang", @"zao", @"ze",
        @"zei", @"zen", @"zeng", @"zi", @"zong",
        @"zou", @"zu", @"zuan", @"zui", @"zun",
        @"zuo", @"zha", @"zhai", @"zhan", @"zhang",
        @"zhao", @"zhe", @"zhei", @"zhen", @"zheng",
        @"zhi", @"zhong", @"zhou", @"zhu", @"zhua",
        @"zhuai", @"zhuan", @"zhuang", @"zhui", @"zhun",
        @"zhuo",
    ];
}

@end
