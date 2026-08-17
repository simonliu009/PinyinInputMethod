/*
 * PinyinInputMethod - macOS 拼音输入�?
 * PinyinParser.m - 拼音解析器实�?
 *
 * 使用动态规划算法进行拼音拆分，结合拼音合法性校�?
 */

#import "PinyinParser.h"

@implementation PinyinParser {
    NSSet<NSString *> *_validPinyins;
    NSSet<NSString *> *_initials;
    NSDictionary<NSString *, NSArray<NSString *> *> *_pinyinInitialMap; // 声母 -> 可能的后续拼�?
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadPinyinTable];
    }
    return self;
}

#pragma mark - 拼音表加�?

- (void)loadPinyinTable {
    // 标准普通话所有合法拼音音节（共约 400 个）
    NSArray *pinyinList = @[
        // a 系列
        @"a", @"ai", @"an", @"ang", @"ao",
        // b 系列
        @"ba", @"bai", @"ban", @"bang", @"bao", @"bei", @"ben", @"beng", @"bi",
        @"bian", @"biao", @"bie", @"bin", @"bing", @"bo", @"bu",
        // c 系列
        @"ca", @"cai", @"can", @"cang", @"cao", @"ce", @"cen", @"ceng", @"ci",
        @"cong", @"cou", @"cu", @"cuan", @"cui", @"cun", @"cuo",
        // ch 系列
        @"cha", @"chai", @"chan", @"chang", @"chao", @"che", @"chen", @"cheng",
        @"chi", @"chong", @"chou", @"chu", @"chua", @"chuai", @"chuan", @"chuang",
        @"chui", @"chun", @"chuo",
        // d 系列
        @"da", @"dai", @"dan", @"dang", @"dao", @"de", @"dei", @"den", @"deng",
        @"di", @"dia", @"dian", @"diao", @"die", @"ding", @"diu", @"dong", @"dou",
        @"du", @"duan", @"dui", @"dun", @"duo",
        // e 系列
        @"e", @"ei", @"en", @"eng", @"er",
        // f 系列
        @"fa", @"fan", @"fang", @"fei", @"fen", @"feng", @"fo", @"fou", @"fu",
        // g 系列
        @"ga", @"gai", @"gan", @"gang", @"gao", @"ge", @"gei", @"gen", @"geng",
        @"gong", @"gou", @"gu", @"gua", @"guai", @"guan", @"guang", @"gui",
        @"gun", @"guo",
        // h 系列
        @"ha", @"hai", @"han", @"hang", @"hao", @"he", @"hei", @"hen", @"heng",
        @"hong", @"hou", @"hu", @"hua", @"huai", @"huan", @"huang", @"hui",
        @"hun", @"huo",
        // j 系列
        @"ji", @"jia", @"jian", @"jiang", @"jiao", @"jie", @"jin", @"jing",
        @"jiong", @"jiu", @"ju", @"juan", @"jue", @"jun",
        // k 系列
        @"ka", @"kai", @"kan", @"kang", @"kao", @"ke", @"kei", @"ken", @"keng",
        @"kong", @"kou", @"ku", @"kua", @"kuai", @"kuan", @"kuang", @"kui",
        @"kun", @"kuo",
        // l 系列
        @"la", @"lai", @"lan", @"lang", @"lao", @"le", @"lei", @"leng", @"li",
        @"lia", @"lian", @"liang", @"liao", @"lie", @"lin", @"ling", @"liu",
        @"lo", @"long", @"lou", @"lu", @"luan", @"lun", @"luo", @"lv", @"lve",
        // m 系列
        @"ma", @"mai", @"man", @"mang", @"mao", @"me", @"mei", @"men", @"meng",
        @"mi", @"mian", @"miao", @"mie", @"min", @"ming", @"miu", @"mo", @"mou",
        @"mu",
        // n 系列
        @"na", @"nai", @"nan", @"nang", @"nao", @"ne", @"nei", @"nen", @"neng",
        @"ni", @"nian", @"niang", @"niao", @"nie", @"nin", @"ning", @"niu",
        @"nong", @"nou", @"nu", @"nuan", @"nun", @"nuo", @"nv", @"nve",
        // o 系列
        @"o", @"ou",
        // p 系列
        @"pa", @"pai", @"pan", @"pang", @"pao", @"pei", @"pen", @"peng", @"pi",
        @"pian", @"piao", @"pie", @"pin", @"ping", @"po", @"pou", @"pu",
        // q 系列
        @"qi", @"qia", @"qian", @"qiang", @"qiao", @"qie", @"qin", @"qing",
        @"qiong", @"qiu", @"qu", @"quan", @"que", @"qun",
        // r 系列
        @"ran", @"rang", @"rao", @"re", @"ren", @"reng", @"ri", @"rong", @"rou",
        @"ru", @"rua", @"ruan", @"rui", @"run", @"ruo",
        // s 系列
        @"sa", @"sai", @"san", @"sang", @"sao", @"se", @"sen", @"seng", @"si",
        @"song", @"sou", @"su", @"suan", @"sui", @"sun", @"suo",
        // sh 系列
        @"sha", @"shai", @"shan", @"shang", @"shao", @"she", @"shei", @"shen",
        @"sheng", @"shi", @"shou", @"shu", @"shua", @"shuai", @"shuan", @"shuang",
        @"shui", @"shun", @"shuo",
        // t 系列
        @"ta", @"tai", @"tan", @"tang", @"tao", @"te", @"tei", @"teng", @"ti",
        @"tian", @"tiao", @"tie", @"ting", @"tong", @"tou", @"tu", @"tuan",
        @"tui", @"tun", @"tuo",
        // w 系列
        @"wa", @"wai", @"wan", @"wang", @"wei", @"wen", @"weng", @"wo", @"wu",
        // x 系列
        @"xi", @"xia", @"xian", @"xiang", @"xiao", @"xie", @"xin", @"xing",
        @"xiong", @"xiu", @"xu", @"xuan", @"xue", @"xun",
        // y 系列
        @"ya", @"yan", @"yang", @"yao", @"ye", @"yi", @"yin", @"ying", @"yo",
        @"yong", @"you", @"yu", @"yuan", @"yue", @"yun",
        // z 系列
        @"za", @"zai", @"zan", @"zang", @"zao", @"ze", @"zei", @"zen", @"zeng",
        @"zi", @"zong", @"zou", @"zu", @"zuan", @"zui", @"zun", @"zuo",
        // zh 系列
        @"zha", @"zhai", @"zhan", @"zhang", @"zhao", @"zhe", @"zhei", @"zhen",
        @"zheng", @"zhi", @"zhong", @"zhou", @"zhu", @"zhua", @"zhuai", @"zhuan",
        @"zhuang", @"zhui", @"zhun", @"zhuo",
    ];
    
    _validPinyins = [NSSet setWithArray:pinyinList];
    
    // 声母�?
    NSArray *initialList = @[
        @"b", @"p", @"m", @"f",
        @"d", @"t", @"n", @"l",
        @"g", @"k", @"h",
        @"j", @"q", @"x",
        @"zh", @"ch", @"sh", @"r",
        @"z", @"c", @"s",
        @"y", @"w",
    ];
    _initials = [NSSet setWithArray:initialList];
    
    NSLog(@"[PinyinParser] 加载拼音表完成，�?%lu 个音�?, (unsigned long)pinyinList.count);
}

- (NSSet<NSString *> *)validPinyins {
    return _validPinyins;
}

- (NSSet<NSString *> *)initials {
    return _initials;
}

#pragma mark - 拼音拆分（动态规划）

- (NSArray<NSArray<NSString *> *> *)splitPinyinString:(NSString *)input {
    if (input.length == 0) return @[];
    
    NSString *lowerInput = [input lowercaseString];
    NSInteger len = lowerInput.length;
    
    // dp[i] 存储从位�?i 到末尾的所有合法拆分方�?
    NSMutableDictionary<NSNumber *, NSMutableArray<NSArray<NSString *> *> *> *dp =
        [NSMutableDictionary dictionary];
    
    // 从后往前填�?
    dp[@(len)] = [NSMutableArray arrayWithObject:@[]];
    
    for (NSInteger i = len - 1; i >= 0; i--) {
        NSMutableArray<NSArray<NSString *> *> *splits = [NSMutableArray array];
        
        // 尝试所有可能的拼音前缀（最�?6 个字符，�?"zhuang"�?
        NSInteger maxLen = MIN((NSInteger)6, len - i);
        for (NSInteger l = maxLen; l >= 1; l--) {
            NSString *prefix = [lowerInput substringWithRange:NSMakeRange(i, l)];
            
            if ([_validPinyins containsObject:prefix]) {
                NSArray<NSArray<NSString *> *> *restSplits = dp[@(i + l)];
                if (restSplits) {
                    for (NSArray<NSString *> *rest in restSplits) {
                        NSMutableArray *newSplit = [NSMutableArray arrayWithObject:prefix];
                        [newSplit addObjectsFromArray:rest];
                        [splits addObject:newSplit];
                    }
                }
            }
        }
        
        if (splits.count > 0) {
            dp[@(i)] = splits;
        }
    }
    
    NSArray<NSArray<NSString *> *> *result = dp[@(0)];
    if (!result) return @[];
    
    // 按优先级排序：优先选择音节数少的方案（更符合中文习惯）
    result = [result sortedArrayUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
        if (a.count < b.count) return NSOrderedAscending;
        if (a.count > b.count) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    // 限制返回方案数量，避免过�?
    if (result.count > 20) {
        result = [result subarrayWithRange:NSMakeRange(0, 20)];
    }
    
    return result;
}

#pragma mark - 拼音校验

- (BOOL)isValidPinyin:(NSString *)pinyin {
    if (!pinyin || pinyin.length == 0) return NO;
    return [_validPinyins containsObject:[pinyin lowercaseString]];
}

#pragma mark - 声母韵母分离

- (NSString *)getInitial:(NSString *)pinyin {
    if (!pinyin || pinyin.length == 0) return @"";
    
    NSString *lower = [pinyin lowercaseString];
    
    // 先检查双字母声母
    if (lower.length >= 2) {
        NSString *twoChar = [lower substringWithRange:NSMakeRange(0, 2)];
        if ([twoChar isEqualToString:@"zh"] ||
            [twoChar isEqualToString:@"ch"] ||
            [twoChar isEqualToString:@"sh"]) {
            return twoChar;
        }
    }
    
    // 再检查单字母声母
    if (lower.length >= 1) {
        NSString *oneChar = [lower substringWithRange:NSMakeRange(0, 1)];
        if ([_initials containsObject:oneChar]) {
            return oneChar;
        }
    }
    
    return @"";  // 零声�?
}

- (NSString *)getFinal:(NSString *)pinyin {
    if (!pinyin || pinyin.length == 0) return @"";
    
    NSString *initial = [self getInitial:pinyin];
    if (initial.length >= pinyin.length) return @"";
    
    return [pinyin substringFromIndex:initial.length];
}

@end
