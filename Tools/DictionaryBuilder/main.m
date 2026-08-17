/*
 * PinyinInputMethod - macOS 拼音输入法
 * Tools/DictionaryBuilder/main.m
 *
 * 命令行工具：将文本格式词库编译为 SQLite 数据库
 * 用法：DictionaryBuilder <output.db> <input1.txt> [input2.txt ...]
 *
 * 输入格式（每行一条）：
 *   词语\t拼音\t词频[\t来源]
 *
 * 编译：clang -framework Foundation -o DictionaryBuilder main.m
 */

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#pragma mark - 函数声明

static BOOL createDatabase(NSString *dbPath, sqlite3 **db);
static NSInteger importFile(sqlite3 *db, NSString *filePath, NSInteger source);
static void printUsage(void);
static void printStats(sqlite3 *db);

#pragma mark - 主函数

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            printUsage();
            return 1;
        }
        
        NSString *outputPath = [NSString stringWithUTF8String:argv[1]];
        NSLog(@"[DictionaryBuilder] 输出文件: %@", outputPath);
        
        // 删除已存在的数据库
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        
        // 创建数据库
        sqlite3 *db = NULL;
        if (!createDatabase(outputPath, &db)) {
            NSLog(@"[DictionaryBuilder] 错误：无法创建数据库");
            return 1;
        }
        
        NSInteger totalCount = 0;
        NSInteger totalErrors = 0;
        NSDate *startTime = [NSDate date];
        
        // 导入每个输入文件
        for (int i = 2; i < argc; i++) {
            NSString *inputPath = [NSString stringWithUTF8String:argv[i]];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
                NSLog(@"[DictionaryBuilder] 警告：文件不存在 %@", inputPath);
                continue;
            }
            
            NSLog(@"\n[DictionaryBuilder] 导入文件: %@", inputPath);
            NSInteger count = importFile(db, inputPath, 0);
            totalCount += count;
            NSLog(@"[DictionaryBuilder] 完成: %ld 条词条", (long)count);
        }
        
        // 写入元数据
        const char *metaSQL = "INSERT OR REPLACE INTO dictionary_meta (key, value) VALUES (?, ?)";
        sqlite3_stmt *metaStmt;
        if (sqlite3_prepare_v2(db, metaSQL, -1, &metaStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(metaStmt, 1, "version", -1, SQLITE_STATIC);
            sqlite3_bind_text(metaStmt, 2, "1.0", -1, SQLITE_STATIC);
            sqlite3_step(metaStmt);
            sqlite3_finalize(metaStmt);
            
            sqlite3_prepare_v2(db, metaSQL, -1, &metaStmt, NULL);
            sqlite3_bind_text(metaStmt, 1, "build_time", -1, SQLITE_STATIC);
            
            NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
            fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSString *timeStr = [fmt stringFromDate:[NSDate date]];
            sqlite3_bind_text(metaStmt, 2, [timeStr UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(metaStmt);
            sqlite3_finalize(metaStmt);
        }
        
        // 统计信息
        NSTimeInterval elapsed = -[startTime timeIntervalSinceNow];
        NSLog(@"\n========================================");
        NSLog(@"[DictionaryBuilder] 编译完成!");
        printStats(db);
        NSLog(@"[DictionaryBuilder] 总导入: %ld 条", (long)totalCount);
        NSLog(@"[DictionaryBuilder] 耗时: %.2f 秒", elapsed);
        
        // 文件大小
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:outputPath error:nil];
        if (attrs) {
            NSLog(@"[DictionaryBuilder] 文件大小: %.1f KB", [attrs fileSize] / 1024.0);
        }
        NSLog(@"========================================");
        
        sqlite3_close(db);
        return 0;
    }
}

#pragma mark - 数据库创建

static BOOL createDatabase(NSString *dbPath, sqlite3 **db) {
    int result = sqlite3_open([dbPath UTF8String], db);
    if (result != SQLITE_OK) {
        NSLog(@"[DictionaryBuilder] 打开数据库失败: %s", sqlite3_errmsg(*db));
        return NO;
    }
    
    // 性能优化
    sqlite3_exec(*db, "PRAGMA journal_mode=WAL", NULL, NULL, NULL);
    sqlite3_exec(*db, "PRAGMA synchronous=NORMAL", NULL, NULL, NULL);
    sqlite3_exec(*db, "PRAGMA cache_size=20000", NULL, NULL, NULL);
    sqlite3_exec(*db, "PRAGMA temp_store=MEMORY", NULL, NULL, NULL);
    
    // 创建表结构
    const char *sql =
        "CREATE TABLE IF NOT EXISTS words ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  word TEXT NOT NULL,"
        "  pinyin TEXT NOT NULL,"
        "  frequency INTEGER DEFAULT 0,"
        "  source INTEGER DEFAULT 0,"
        "  user_data TEXT,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE INDEX IF NOT EXISTS idx_words_pinyin ON words(pinyin);"
        "CREATE INDEX IF NOT EXISTS idx_words_frequency ON words(frequency DESC);"
        "CREATE INDEX IF NOT EXISTS idx_words_source ON words(source);"
        "CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);"
        ""
        "CREATE TABLE IF NOT EXISTS user_habits ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pinyin TEXT NOT NULL,"
        "  word TEXT NOT NULL,"
        "  hit_count INTEGER DEFAULT 1,"
        "  last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  UNIQUE(pinyin, word)"
        ");"
        "CREATE INDEX IF NOT EXISTS idx_habits_pinyin ON user_habits(pinyin);"
        ""
        "CREATE TABLE IF NOT EXISTS dictionary_meta ("
        "  key TEXT PRIMARY KEY,"
        "  value TEXT"
        ");";
    
    char *errMsg = NULL;
    result = sqlite3_exec(*db, sql, NULL, NULL, &errMsg);
    if (result != SQLITE_OK) {
        NSLog(@"[DictionaryBuilder] 创建表失败: %s", errMsg);
        sqlite3_free(errMsg);
        return NO;
    }
    
    NSLog(@"[DictionaryBuilder] 数据库结构已创建");
    return YES;
}

#pragma mark - 文件导入

static NSInteger importFile(sqlite3 *db, NSString *filePath, NSInteger source) {
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    if (!content) {
        // 尝试 GBK 编码
        content = [NSString stringWithContentsOfFile:filePath
                                            encoding:CFStringConvertEncodingToNSStringEncoding(CFStringEncodingGB_18030_2000)
                                               error:nil];
    }
    
    if (!content) {
        NSLog(@"[DictionaryBuilder] 无法读取文件: %@", filePath);
        return 0;
    }
    
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // 开启事务
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    const char *sql = "INSERT OR IGNORE INTO words (word, pinyin, frequency, source) VALUES (?, ?, ?, ?)";
    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
    
    NSInteger count = 0;
    NSInteger errors = 0;
    NSInteger lineNum = 0;
    
    for (NSString *line in lines) {
        lineNum++;
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // 跳过空行和注释
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;
        
        // 解析：支持 Tab 和空格分隔
        NSArray *parts;
        if ([trimmed containsString:@"\t"]) {
            parts = [trimmed componentsSeparatedByString:@"\t"];
        } else {
            parts = [trimmed componentsSeparatedByString:@" "];
        }
        
        // 清理空字符串
        NSMutableArray *cleanParts = [NSMutableArray array];
        for (NSString *part in parts) {
            NSString *clean = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (clean.length > 0) {
                [cleanParts addObject:clean];
            }
        }
        
        if (cleanParts.count < 2) {
            errors++;
            if (errors <= 5) {
                NSLog(@"[DictionaryBuilder] 第 %ld 行格式错误: %@", (long)lineNum, trimmed);
            }
            continue;
        }
        
        NSString *word = cleanParts[0];
        NSString *pinyin = [cleanParts[1] lowercaseString];
        NSInteger freq = cleanParts.count >= 3 ? [cleanParts[2] integerValue] : 1000;
        NSInteger src = cleanParts.count >= 4 ? [cleanParts[3] integerValue] : source;
        
        sqlite3_reset(stmt);
        sqlite3_bind_text(stmt, 1, [word UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(stmt, 3, freq);
        sqlite3_bind_int(stmt, 4, (int)src);
        
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            count++;
        } else {
            errors++;
        }
        
        // 每 10000 条提交一次
        if (count % 10000 == 0 && count > 0) {
            sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
            NSLog(@"[DictionaryBuilder]   已导入 %ld 条...", (long)count);
            sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
        }
    }
    
    sqlite3_finalize(stmt);
    sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
    
    if (errors > 0) {
        NSLog(@"[DictionaryBuilder] 共 %ld 行解析错误", (long)errors);
    }
    
    return count;
}

#pragma mark - 统计信息

static void printStats(sqlite3 *db) {
    sqlite3_stmt *stmt;
    
    // 总词条数
    if (sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM words", -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            NSLog(@"[DictionaryBuilder] 总词条数: %lld", sqlite3_column_int64(stmt, 0));
        }
        sqlite3_finalize(stmt);
    }
    
    // 拼音数
    if (sqlite3_prepare_v2(db, "SELECT COUNT(DISTINCT pinyin) FROM words", -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            NSLog(@"[DictionaryBuilder] 拼音音节数: %lld", sqlite3_column_int64(stmt, 0));
        }
        sqlite3_finalize(stmt);
    }
    
    // 各来源统计
    if (sqlite3_prepare_v2(db, "SELECT source, COUNT(*) FROM words GROUP BY source", -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSInteger src = sqlite3_column_int(stmt, 0);
            NSInteger cnt = sqlite3_column_int64(stmt, 1);
            NSString *srcName;
            switch (src) {
                case 0: srcName = @"基础词库"; break;
                case 1: srcName = @"搜狗词库"; break;
                case 2: srcName = @"用户词库"; break;
                default: srcName = [NSString stringWithFormat:@"来源%ld", (long)src]; break;
            }
            NSLog(@"[DictionaryBuilder]   %@: %lld 条", srcName, cnt);
        }
        sqlite3_finalize(stmt);
    }
}

#pragma mark - 帮助

static void printUsage(void) {
    NSLog(@"===========================================");
    NSLog(@"PinyinInputMethod 词库编译工具");
    NSLog(@"===========================================");
    NSLog(@"");
    NSLog(@"用法: DictionaryBuilder <输出.db> <输入1.txt> [输入2.txt ...]");
    NSLog(@"");
    NSLog(@"输入文件格式（每行一条）:");
    NSLog(@"  词语\\t拼音\\t词频[\\t来源]");
    NSLog(@"");
    NSLog(@"示例:");
    NSLog(@"  我们\\two men\\t450000");
    NSLog(@"  中国\\tzhong guo\\t440000");
    NSLog(@"  拼音\\tpin yin\\t130000\\t0");
    NSLog(@"");
    NSLog(@"来源值: 0=基础, 1=搜狗, 2=用户");
    NSLog(@"以 # 开头的行为注释，空行会被忽略");
    NSLog(@"===========================================");
}
