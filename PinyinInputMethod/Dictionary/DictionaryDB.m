/*
 * PinyinInputMethod - macOS 拼音输入法
 * DictionaryDB.m - SQLite 数据库操作实现
 */

#import "DictionaryDB.h"

@implementation DictionaryDB {
    sqlite3 *_db;
    dispatch_queue_t _dbQueue;  // 串行队列，保证线程安全
}

#pragma mark - 初始化

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _databasePath = [path copy];
        _dbQueue = dispatch_queue_create("com.pinyin.dictionary.db", DISPATCH_QUEUE_SERIAL);
        
        if (![self open]) {
            NSLog(@"[DictionaryDB] 错误：无法打开数据库 %@", path);
            return nil;
        }
        
        if (![self createTables]) {
            NSLog(@"[DictionaryDB] 错误：无法创建表结构");
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self close];
}

#pragma mark - 数据库连接

- (BOOL)open {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        int result = sqlite3_open([self->_databasePath UTF8String], &self->_db);
        if (result != SQLITE_OK) {
            NSLog(@"[DictionaryDB] 打开数据库失败: %s", sqlite3_errmsg(self->_db));
            return;
        }
        
        // 设置 pragmas 优化性能
        sqlite3_exec(self->_db, "PRAGMA journal_mode=WAL", NULL, NULL, NULL);
        sqlite3_exec(self->_db, "PRAGMA synchronous=NORMAL", NULL, NULL, NULL);
        sqlite3_exec(self->_db, "PRAGMA cache_size=10000", NULL, NULL, NULL);
        sqlite3_exec(self->_db, "PRAGMA temp_store=MEMORY", NULL, NULL, NULL);
        
        success = YES;
        NSLog(@"[DictionaryDB] 数据库已打开: %@", self->_databasePath);
    });
    
    return success;
}

- (void)close {
    dispatch_sync(_dbQueue, ^{
        if (self->_db) {
            sqlite3_close(self->_db);
            self->_db = NULL;
            NSLog(@"[DictionaryDB] 数据库已关闭");
        }
    });
}

#pragma mark - 表结构

- (BOOL)createTables {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
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
        int result = sqlite3_exec(self->_db, sql, NULL, NULL, &errMsg);
        if (result != SQLITE_OK) {
            NSLog(@"[DictionaryDB] 创建表失败: %s", errMsg);
            sqlite3_free(errMsg);
            return;
        }
        
        success = YES;
    });
    
    return success;
}

#pragma mark - 词条操作

- (BOOL)insertWord:(NSString *)word pinyin:(NSString *)pinyin 
         frequency:(NSInteger)frequency source:(NSInteger)source
{
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "INSERT OR IGNORE INTO words (word, pinyin, frequency, source) VALUES (?, ?, ?, ?)";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"[DictionaryDB] prepare 失败: %s", sqlite3_errmsg(self->_db));
            return;
        }
        
        sqlite3_bind_text(stmt, 1, [word UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(stmt, 3, frequency);
        sqlite3_bind_int(stmt, 4, (int)source);
        
        success = (sqlite3_step(stmt) == SQLITE_DONE);
        sqlite3_finalize(stmt);
    });
    
    return success;
}

- (BOOL)insertWords:(NSArray<NSDictionary *> *)words {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        // 开启事务
        sqlite3_exec(self->_db, "BEGIN TRANSACTION", NULL, NULL, NULL);
        
        const char *sql = "INSERT OR IGNORE INTO words (word, pinyin, frequency, source) VALUES (?, ?, ?, ?)";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) {
            sqlite3_exec(self->_db, "ROLLBACK", NULL, NULL, NULL);
            return;
        }
        
        for (NSDictionary *wordDict in words) {
            sqlite3_reset(stmt);
            
            NSString *word = wordDict[@"word"];
            NSString *pinyin = wordDict[@"pinyin"];
            NSInteger freq = [wordDict[@"frequency"] integerValue];
            NSInteger src = [wordDict[@"source"] integerValue];
            
            sqlite3_bind_text(stmt, 1, [word UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(stmt, 3, freq);
            sqlite3_bind_int(stmt, 4, (int)src);
            
            sqlite3_step(stmt);
        }
        
        sqlite3_finalize(stmt);
        sqlite3_exec(self->_db, "COMMIT", NULL, NULL, NULL);
        success = YES;
        
        NSLog(@"[DictionaryDB] 批量插入 %lu 条词条", (unsigned long)words.count);
    });
    
    return success;
}

- (NSArray<NSDictionary *> *)queryWordsWithPinyin:(NSString *)pinyin {
    __block NSMutableArray *results = [NSMutableArray array];
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "SELECT word, pinyin, frequency, source FROM words WHERE pinyin = ? ORDER BY frequency DESC LIMIT 100";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) {
            return;
        }
        
        sqlite3_bind_text(stmt, 1, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSDictionary *dict = @{
                @"word": @(sqlite3_column_text(stmt, 0) ? (const char *)sqlite3_column_text(stmt, 0) : ""),
                @"pinyin": @(sqlite3_column_text(stmt, 1) ? (const char *)sqlite3_column_text(stmt, 1) : ""),
                @"frequency": @(sqlite3_column_int64(stmt, 2)),
                @"source": @(sqlite3_column_int(stmt, 3)),
            };
            [results addObject:dict];
        }
        
        sqlite3_finalize(stmt);
    });
    
    return results;
}

- (NSArray<NSDictionary *> *)queryWordsWithPinyinPrefix:(NSString *)prefix limit:(NSInteger)limit {
    __block NSMutableArray *results = [NSMutableArray array];
    
    dispatch_sync(_dbQueue, ^{
        NSString *likeStr = [prefix stringByAppendingString:@"%"];
        const char *sql = "SELECT word, pinyin, frequency, source FROM words WHERE pinyin LIKE ? ORDER BY frequency DESC LIMIT ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) {
            return;
        }
        
        sqlite3_bind_text(stmt, 1, [likeStr UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt, 2, (int)limit);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSDictionary *dict = @{
                @"word": @(sqlite3_column_text(stmt, 0) ? (const char *)sqlite3_column_text(stmt, 0) : ""),
                @"pinyin": @(sqlite3_column_text(stmt, 1) ? (const char *)sqlite3_column_text(stmt, 1) : ""),
                @"frequency": @(sqlite3_column_int64(stmt, 2)),
                @"source": @(sqlite3_column_int(stmt, 3)),
            };
            [results addObject:dict];
        }
        
        sqlite3_finalize(stmt);
    });
    
    return results;
}

- (BOOL)updateFrequency:(NSInteger)frequency forWord:(NSString *)word pinyin:(NSString *)pinyin {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "UPDATE words SET frequency = ? WHERE word = ? AND pinyin = ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) return;
        
        sqlite3_bind_int64(stmt, 1, frequency);
        sqlite3_bind_text(stmt, 2, [word UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 3, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        
        success = (sqlite3_step(stmt) == SQLITE_DONE);
        sqlite3_finalize(stmt);
    });
    
    return success;
}

- (BOOL)deleteWord:(NSString *)word pinyin:(NSString *)pinyin {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "DELETE FROM words WHERE word = ? AND pinyin = ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) return;
        
        sqlite3_bind_text(stmt, 1, [word UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        
        success = (sqlite3_step(stmt) == SQLITE_DONE);
        sqlite3_finalize(stmt);
    });
    
    return success;
}

- (BOOL)deleteWordsWithSource:(NSInteger)source {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "DELETE FROM words WHERE source = ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) return;
        
        sqlite3_bind_int(stmt, 1, (int)source);
        
        success = (sqlite3_step(stmt) == SQLITE_DONE);
        sqlite3_finalize(stmt);
    });
    
    return success;
}

#pragma mark - 用户习惯

- (BOOL)recordUserHabit:(NSString *)pinyin word:(NSString *)word {
    __block BOOL success = NO;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = 
            "INSERT INTO user_habits (pinyin, word, hit_count, last_used) "
            "VALUES (?, ?, 1, datetime('now')) "
            "ON CONFLICT(pinyin, word) DO UPDATE SET "
            "hit_count = hit_count + 1, last_used = datetime('now')";
        
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) return;
        
        sqlite3_bind_text(stmt, 1, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [word UTF8String], -1, SQLITE_TRANSIENT);
        
        success = (sqlite3_step(stmt) == SQLITE_DONE);
        sqlite3_finalize(stmt);
    });
    
    return success;
}

- (NSArray<NSDictionary *> *)getUserHabitsForPinyin:(NSString *)pinyin limit:(NSInteger)limit {
    __block NSMutableArray *results = [NSMutableArray array];
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "SELECT word, hit_count, last_used FROM user_habits WHERE pinyin = ? ORDER BY hit_count DESC LIMIT ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) != SQLITE_OK) return;
        
        sqlite3_bind_text(stmt, 1, [pinyin UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt, 2, (int)limit);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSDictionary *dict = @{
                @"word": @(sqlite3_column_text(stmt, 0) ? (const char *)sqlite3_column_text(stmt, 0) : ""),
                @"hit_count": @(sqlite3_column_int(stmt, 1)),
                @"last_used": @(sqlite3_column_text(stmt, 2) ? (const char *)sqlite3_column_text(stmt, 2) : ""),
            };
            [results addObject:dict];
        }
        
        sqlite3_finalize(stmt);
    });
    
    return results;
}

#pragma mark - 统计

- (NSInteger)totalWordCount {
    __block NSInteger count = 0;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "SELECT COUNT(*) FROM words";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                count = sqlite3_column_int64(stmt, 0);
            }
            sqlite3_finalize(stmt);
        }
    });
    
    return count;
}

- (NSInteger)wordCountForSource:(NSInteger)source {
    __block NSInteger count = 0;
    
    dispatch_sync(_dbQueue, ^{
        const char *sql = "SELECT COUNT(*) FROM words WHERE source = ?";
        sqlite3_stmt *stmt;
        
        if (sqlite3_prepare_v2(self->_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, (int)source);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                count = sqlite3_column_int64(stmt, 0);
            }
            sqlite3_finalize(stmt);
        }
    });
    
    return count;
}

@end
