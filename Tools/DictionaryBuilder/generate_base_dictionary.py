#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
基础词库生成器
生成约5万条拼音-汉字映射词条，用于构建 pinyin_base.db

用法: python3 generate_base_dictionary.py
输出: ../PinyinInputMethod/Resources/pinyin_map.txt
"""

import os
import sys
import importlib.util


def load_module(filename):
    """加载 Python 数据模块"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    filepath = os.path.join(script_dir, filename)
    spec = importlib.util.spec_from_file_location("data_mod_" + filename, filepath)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def build_char_pinyin(char_data_1, char_data_2):
    """合并字符拼音数据，返回 {pinyin: [chars]} 和 {char: pinyin}"""
    py_to_chars = {}
    py_to_chars.update(char_data_1.CHAR_PINYIN)
    py_to_chars.update(char_data_2.CHAR_PINYIN)
    
    char_to_py = {}
    for pinyin, chars in py_to_chars.items():
        for ch in chars:
            if ch not in char_to_py:
                char_to_py[ch] = pinyin
    return py_to_chars, char_to_py


def get_word_pinyin(word, char_to_py):
    """获取词语的拼音（空格分隔）"""
    parts = []
    for ch in word:
        if ch in char_to_py:
            parts.append(char_to_py[ch])
        else:
            return None
    return ' '.join(parts)


def generate_single_chars(py_to_chars):
    """生成单字词条"""
    entries = []
    for pinyin, chars in py_to_chars.items():
        base_freq = 1000000 // (len(chars) + 1)
        for i, char in enumerate(chars):
            freq = max(100, base_freq // (i + 1))
            entries.append((char, pinyin, freq))
    return entries


def generate_from_word_list(words, char_to_py, base_freq=50000, step=200):
    """从词语列表生成词条（自动计算拼音）"""
    entries = []
    freq = base_freq
    for word in words:
        pinyin = get_word_pinyin(word, char_to_py)
        if pinyin:
            entries.append((word, pinyin, freq))
            freq = max(100, freq - step)
    return entries


def generate_idioms(idioms, base_freq=6000, step=30):
    """从成语列表生成词条"""
    entries = []
    freq = base_freq
    for word, pinyin in idioms:
        entries.append((word, pinyin, freq))
        freq = max(100, freq - step)
    return entries


def generate_explicit_words(words_with_pinyin, base_freq=10000, step=50):
    """从带拼音的词组列表生成词条"""
    entries = []
    freq = base_freq
    for word, pinyin in words_with_pinyin:
        entries.append((word, pinyin, freq))
        freq = max(100, freq - step)
    return entries


def generate_combination_words(py_to_chars, char_to_py):
    """通过常见字组合生成大量合理词条"""
    entries = []
    
    # 常见构词首字（300+高频字，适合做词头）
    head_chars = (
        '上下中为人出作光明利国天好学实小工年心手文新时明有用自行见长门分间点方'
        '生大来地过之去事二第先民气员通全场别内师等入面正老世力部意外体制回'
        '所当前路位种法问定平更打理水四动八相前高被做成什只本接比最重开教'
        '名反切总已情公百原已各解名合命达许论设义管现表先利给但知如相往'
        '清政经军意民报安指变思相指支收改放取受合升运进退连近远速造适追'
        '转输迎送述退选逐通递逻遍那都配醒采金释钢银错锁锐错锦锡镇镶周'
        '品商善堂堂富寄密察导寻封射尊展属巡差已巩己巷带帮干并幸广庄应废'
    )
    # 常见构词尾字（300+高频字，适合做词尾）
    tail_chars = (
        '了子的人地在大是好时有的不个中上下来去后着过到说看想让成回种面部分'
        '头方式度长进性心手力口日气话目眼法风车路书声字眼脚步心点国年家'
        '门日方水问题意情事理力世件处所名光花道果城村东西义主代化全区系'
        '活命正业功加象水品级比员度利思才值况效角务算机语制件表领张图关'
        '质类型态势局局层环象段面步武止例供凭候光克免册击切制剂副功动'
        '包化区升印卷卫厂厅历去台右号司各合同名向否吧员味和品器回园围国'
        '图圈地场块坛垂型域培基堂堆堡增处备复夏夜梦大天太头夸奇奖套好'
    )
    
    # 按声母分组
    chars_by_initial = {}
    for pinyin, chars in py_to_chars.items():
        initial = ''
        for ch in sorted(['zh','ch','sh','b','p','m','f','d','t','n','l','g','k','h',
                          'j','q','x','z','c','s','r','y','w'], key=len, reverse=True):
            if pinyin.startswith(ch):
                initial = ch
                break
        if not initial and pinyin[0] in 'aeo':
            initial = pinyin[0]
        if initial not in chars_by_initial:
            chars_by_initial[initial] = []
        chars_by_initial[initial].extend(chars[:8])
    
    # 常见声母组合及其基础词频
    initial_pairs = [
        ('x', 'sh', 9000), ('zh', 'sh', 8500), ('g', 'j', 8000),
        ('d', 'zh', 7500), ('b', 'm', 7000), ('h', 'l', 6500),
        ('s', 'sh', 6000), ('z', 'zh', 5800), ('t', 'd', 5500),
        ('q', 'x', 5200), ('y', 'w', 5000), ('c', 'ch', 4800),
        ('j', 'q', 4600), ('m', 'n', 4400), ('f', 'h', 4200),
        ('l', 'r', 4000), ('k', 'g', 3800), ('p', 'b', 3600),
        ('sh', 'zh', 3400), ('ch', 'sh', 3200), ('n', 'l', 3000),
        ('w', 'y', 2800), ('d', 't', 2600), ('g', 'k', 2400),
        ('zh', 'ch', 2200), ('s', 'c', 2000), ('z', 's', 1800),
        ('b', 'p', 1600), ('m', 'f', 1500), ('j', 'x', 1400),
        ('x', 'y', 1300), ('zh', 'j', 1200), ('sh', 'x', 1100),
        ('ch', 'c', 1000), ('d', 'l', 900), ('t', 'sh', 850),
        ('n', 'zh', 800), ('l', 'sh', 750), ('r', 'l', 700),
        ('g', 'zh', 650), ('k', 'sh', 600), ('h', 'g', 550),
        ('f', 'b', 500), ('p', 'm', 480), ('w', 'h', 460),
        ('y', 'l', 440), ('j', 'zh', 420), ('q', 'sh', 400),
    ]
    
    for init1, init2, base_freq in initial_pairs:
        chars1 = chars_by_initial.get(init1, [])[:8]
        chars2 = chars_by_initial.get(init2, [])[:8]
        freq = base_freq
        for c1 in chars1:
            for c2 in chars2:
                if c1 != c2:
                    word = c1 + c2
                    pinyin = get_word_pinyin(word, char_to_py)
                    if pinyin:
                        entries.append((word, pinyin, freq))
                        freq = max(50, freq - 20)
    
    # 使用常见首尾字生成更多组合
    freq = 4000
    for h in head_chars:
        for t in tail_chars:
            if h != t:
                word = h + t
                pinyin = get_word_pinyin(word, char_to_py)
                if pinyin:
                    entries.append((word, pinyin, freq))
                    freq = max(50, freq - 2)
    
    # 三字词组合（扩展）
    three_a = '大中小上下新旧人多少好坏天地长左右内外前后高低远近深浅轻重快慢早晚新老第一第三'
    three_b = '国学生人子工心手日月年时分点面线体度性力价质变量率度位期区间层所号'
    three_c = '的子人儿化性力度面线点机体器具物品件员者家院所站场店馆所港口站'
    three_d = '化性度力量化感度性值率性观念观感识知性觉感效应态性'
    
    freq = 2500
    for a in three_a[:25]:
        for c in three_c[:20]:
            if a != c:
                b = three_b[len(three_b)//3]
                word = a + b + c
                pinyin = get_word_pinyin(word, char_to_py)
                if pinyin:
                    entries.append((word, pinyin, freq))
                    freq = max(50, freq - 2)
    
    freq = 2000
    for a in three_a[10:30]:
        for c in three_c[5:25]:
            if a != c:
                b = three_b[len(three_b)*2//3]
                word = a + b + c
                pinyin = get_word_pinyin(word, char_to_py)
                if pinyin:
                    entries.append((word, pinyin, freq))
                    freq = max(50, freq - 2)
    
    freq = 1800
    for a in three_a[:15]:
        for d in three_d[:15]:
            b = three_b[5]
            word = a + b + d
            pinyin = get_word_pinyin(word, char_to_py)
            if pinyin:
                entries.append((word, pinyin, freq))
                freq = max(50, freq - 2)
    
    # 四字词组合（扩展）
    four_a = '和风吹雨雪花云天地山水日月金木火土春夏东南西北东西'
    four_b = '平安全正清明显美善真新光明强大丰高和安乐好静雅秀壮丽宏伟'
    four_c = '乐和顺利泰安康宁静雅秀丽壮观宏伟秀色香臭臭鲜甜苦酸辣咸淡'
    four_d = '歌年景象风光气象局面境界状态形势态势样势态势况景景色色'
    
    freq = 1500
    for a in four_a:
        for b in four_b:
            for d in four_d[:10]:
                word = a + b + four_c[len(four_c)//3] + d
                pinyin = get_word_pinyin(word, char_to_py)
                if pinyin:
                    entries.append((word, pinyin, freq))
                    freq = max(50, freq - 2)
    
    freq = 1200
    for a in four_a[10:]:
        for b in four_b[10:]:
            for d in four_d[5:15]:
                word = a + b + four_c[len(four_c)*2//3] + d
                pinyin = get_word_pinyin(word, char_to_py)
                if pinyin:
                    entries.append((word, pinyin, freq))
                    freq = max(50, freq - 2)
    
    return entries


def main():
    print("=" * 60)
    print("拼音输入法 - 基础词库生成器")
    print("=" * 60)
    
    # 加载数据
    print("\n[1/6] 加载字符数据...")
    cd1 = load_module('char_data_1.py')
    cd2 = load_module('char_data_2.py')
    py_to_chars, char_to_py = build_char_pinyin(cd1, cd2)
    print(f"  已加载 {len(py_to_chars)} 个拼音音节")
    total_chars = sum(len(c) for c in py_to_chars.values())
    print(f"  共 {total_chars} 个汉字")
    
    print("\n[2/6] 生成单字词条...")
    entries = generate_single_chars(py_to_chars)
    print(f"  单字词条: {len(entries)}")
    
    print("\n[3/6] 加载词组数据...")
    wd = load_module('word_data.py')
    
    # 处理 WORDS 列表
    word_entries = generate_from_word_list(wd.WORDS, char_to_py, 55000, 2)
    entries.extend(word_entries)
    print(f"  常用词(WORDS): {len(word_entries)}")
    
    # 处理 IDIOMS
    idiom_entries = generate_idioms(wd.IDIOMS, 6000, 20)
    entries.extend(idiom_entries)
    print(f"  成语(IDIOMS): {len(idiom_entries)}")
    
    # 处理 THREE_CHAR_WORDS
    three_entries = generate_explicit_words(wd.THREE_CHAR_WORDS, 8000, 30)
    entries.extend(three_entries)
    print(f"  三字词: {len(three_entries)}")
    
    # 处理 MULTI_CHAR_WORDS
    multi_entries = generate_explicit_words(wd.MULTI_CHAR_WORDS, 5000, 50)
    entries.extend(multi_entries)
    print(f"  多字词: {len(multi_entries)}")
    
    print("\n[4/6] 生成组合词条...")
    combo_entries = generate_combination_words(py_to_chars, char_to_py)
    entries.extend(combo_entries)
    print(f"  组合词条: {len(combo_entries)}")
    
    # 去重（保留最高词频）
    print("\n[5/6] 去重与排序...")
    word_dict = {}
    for word, pinyin, freq in entries:
        key = (word, pinyin)
        if key not in word_dict or freq > word_dict[key]:
            word_dict[key] = freq
    
    sorted_entries = sorted(word_dict.items(), key=lambda x: -x[1])
    
    # 写入文件 - 使用绝对路径确保正确
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # script_dir = .../Tools/DictionaryBuilder
    # 需要到 .../PinyinInputMethod/Resources/
    project_dir = os.path.dirname(os.path.dirname(script_dir))  # .../PinyinInputMethod
    output_path = os.path.join(project_dir, 'PinyinInputMethod', 'Resources', 'pinyin_map.txt')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# 拼音输入法 - 基础词库\n")
        f.write("# 格式：词语\\t拼音\\t词频\n")
        f.write(f"# 词条总数：{len(sorted_entries)}\n")
        f.write("# 词频范围：1-1000000，数值越大越常用\n")
        f.write("#\n")
        for (word, pinyin), freq in sorted_entries:
            f.write(f"{word}\t{pinyin}\t{freq}\n")
    
    print(f"\n[6/6] 生成完成！")
    print(f"\n{'=' * 60}")
    print(f"  词条总数: {len(sorted_entries)}")
    print(f"  输出文件: {output_path}")
    
    single = sum(1 for (w, p), f in sorted_entries if len(w) == 1)
    double = sum(1 for (w, p), f in sorted_entries if len(w) == 2)
    triple = sum(1 for (w, p), f in sorted_entries if len(w) == 3)
    quad = sum(1 for (w, p), f in sorted_entries if len(w) == 4)
    longer = sum(1 for (w, p), f in sorted_entries if len(w) > 4)
    
    print(f"\n  分类统计:")
    print(f"  单字:   {single}")
    print(f"  双字词: {double}")
    print(f"  三字词: {triple}")
    print(f"  四字词: {quad}")
    print(f"  多字词: {longer}")
    print(f"{'=' * 60}")


if __name__ == '__main__':
    main()
