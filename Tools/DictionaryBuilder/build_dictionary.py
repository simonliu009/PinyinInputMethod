#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PinyinInputMethod - 词库编译工具
build_dictionary.py

将文本格式的词库文件编译为 SQLite 数据库
输入格式：每行一个词条，格式为 "词语\t拼音\t词频"
"""

import sqlite3
import sys
import os
import time


def create_database(db_path):
    """创建 SQLite 数据库并初始化表结构"""
    if os.path.exists(db_path):
        os.remove(db_path)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 创建词条表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            pinyin TEXT NOT NULL,
            frequency INTEGER DEFAULT 0,
            source INTEGER DEFAULT 0,
            user_data TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 创建索引
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_words_pinyin ON words(pinyin)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_words_frequency ON words(frequency DESC)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_words_source ON words(source)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word)')
    
    # 创建用户习惯表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pinyin TEXT NOT NULL,
            word TEXT NOT NULL,
            hit_count INTEGER DEFAULT 1,
            last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(pinyin, word)
        )
    ''')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_habits_pinyin ON user_habits(pinyin)')
    
    # 创建元数据表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS dictionary_meta (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    ''')
    
    conn.commit()
    return conn


def parse_line(line):
    """解析一行词条数据"""
    line = line.strip()
    if not line or line.startswith('#'):
        return None
    
    # 支持多种分隔符
    parts = None
    for sep in ['\t', '  ', ' ']:
        parts = line.split(sep)
        parts = [p.strip() for p in parts if p.strip()]
        if len(parts) >= 2:
            break
    
    if not parts or len(parts) < 2:
        return None
    
    word = parts[0]
    pinyin = parts[1].lower()
    frequency = int(parts[2]) if len(parts) >= 3 else 1000
    source = int(parts[3]) if len(parts) >= 4 else 0
    
    return {
        'word': word,
        'pinyin': pinyin,
        'frequency': frequency,
        'source': source,
    }


def import_file(conn, file_path, source=0):
    """导入文本文件到数据库"""
    cursor = conn.cursor()
    count = 0
    errors = 0
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            entry = parse_line(line)
            if entry is None:
                continue
            
            try:
                cursor.execute(
                    'INSERT OR IGNORE INTO words (word, pinyin, frequency, source) VALUES (?, ?, ?, ?)',
                    (entry['word'], entry['pinyin'], entry['frequency'], source)
                )
                count += 1
                
                if count % 10000 == 0:
                    conn.commit()
                    print(f"  已导入 {count} 条...")
                    
            except Exception as e:
                errors += 1
                if errors <= 10:
                    print(f"  第 {line_num} 行错误: {e}")
    
    conn.commit()
    return count, errors


def build_database(input_files, output_path):
    """编译词库数据库"""
    print(f"开始编译词库数据库...")
    print(f"输出文件: {output_path}")
    
    start_time = time.time()
    
    # 创建数据库
    conn = create_database(output_path)
    
    total_count = 0
    total_errors = 0
    
    for input_file in input_files:
        if not os.path.exists(input_file):
            print(f"警告: 文件不存在 {input_file}")
            continue
        
        print(f"\n导入文件: {input_file}")
        count, errors = import_file(conn, input_file)
        total_count += count
        total_errors += errors
        print(f"  完成: {count} 条词条, {errors} 个错误")
    
    # 写入元数据
    cursor = conn.cursor()
    cursor.execute("INSERT OR REPLACE INTO dictionary_meta (key, value) VALUES ('version', '1.0')")
    cursor.execute("INSERT OR REPLACE INTO dictionary_meta (key, value) VALUES ('total_words', ?)", 
                   (str(total_count),))
    cursor.execute("INSERT OR REPLACE INTO dictionary_meta (key, value) VALUES ('build_time', ?)",
                   (time.strftime('%Y-%m-%d %H:%M:%S'),))
    conn.commit()
    
    # 统计
    cursor.execute("SELECT COUNT(*) FROM words")
    db_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(DISTINCT pinyin) FROM words")
    pinyin_count = cursor.fetchone()[0]
    
    conn.close()
    
    elapsed = time.time() - start_time
    print(f"\n编译完成!")
    print(f"  总词条数: {db_count}")
    print(f"  拼音数: {pinyin_count}")
    print(f"  总错误: {total_errors}")
    print(f"  耗时: {elapsed:.2f} 秒")
    print(f"  文件大小: {os.path.getsize(output_path) / 1024:.1f} KB")


def main():
    if len(sys.argv) < 3:
        print("用法: python3 build_dictionary.py <输出.db> <输入1.txt> [输入2.txt ...]")
        print("")
        print("输入文件格式 (每行一条):")
        print("  词语\\t拼音\\t词频")
        print("")
        print("示例:")
        print("  我们\\two men\\t450000")
        print("  中国\\tzhong guo\\t440000")
        sys.exit(1)
    
    output_path = sys.argv[1]
    input_files = sys.argv[2:]
    
    build_database(input_files, output_path)


if __name__ == '__main__':
    main()
