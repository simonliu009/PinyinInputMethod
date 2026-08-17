/*
 * PinyinInputMethod - macOS 拼音输入�?
 * ConfigManager.m - 配置管理实现
 */

#import "ConfigManager.h"

// 配置键名常量
NSString * const kConfigInputMode = @"inputMode";
NSString * const kConfigCandidatesPerPage = @"candidatesPerPage";
NSString * const kConfigFuzzyEnabled = @"fuzzyEnabled";
NSString * const kConfigFuzzyZ_ZH = @"fuzzyZ_ZH";
NSString * const kConfigFuzzyC_CH = @"fuzzyC_CH";
NSString * const kConfigFuzzyS_SH = @"fuzzyS_SH";
NSString * const kConfigFuzzyN_L = @"fuzzyN_L";
NSString * const kConfigFuzzyF_H = @"fuzzyF_H";
NSString * const kConfigFuzzyAn_Ang = @"fuzzyAn_Ang";
NSString * const kConfigFuzzyEn_Eng = @"fuzzyEn_Eng";
NSString * const kConfigFuzzyIn_In = @"fuzzyIn_In";
NSString * const kConfigRememberMode = @"rememberMode";
NSString * const kConfigSwitchKey = @"switchKey";

static NSString * const kConfigDomain = @"com.ximeng.inputmethod.config";

static ConfigManager *sharedInstance = nil;

@implementation ConfigManager {
    NSUserDefaults *_defaults;
    NSMutableDictionary *_cache;
    NSMutableArray *_observers;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _defaults = [NSUserDefaults standardUserDefaults];
        _cache = [NSMutableDictionary dictionary];
        _observers = [NSMutableArray array];
    }
    return self;
}

#pragma mark - 加载/保存

- (void)loadConfig {
    // �?NSUserDefaults 加载所有配置到缓存
    NSDictionary *allDefaults = [self defaultConfig];
    
    for (NSString *key in allDefaults) {
        id value = [_defaults objectForKey:key];
        _cache[key] = value ?: allDefaults[key];
    }
    
    NSLog(@"[ConfigManager] 配置已加载，�?%lu �?, (unsigned long)_cache.count);
}

- (void)saveConfig {
    for (NSString *key in _cache) {
        [_defaults setObject:_cache[key] forKey:key];
    }
    [_defaults synchronize];
    
    NSLog(@"[ConfigManager] 配置已保�?);
}

- (void)resetToDefaults {
    NSDictionary *defaults = [self defaultConfig];
    [_cache setDictionary:defaults];
    [self saveConfig];
    
    // 通知观察�?
    [self notifyObservers];
    
    NSLog(@"[ConfigManager] 配置已重置为默认�?);
}

#pragma mark - 默认配置

- (NSDictionary *)defaultConfig {
    return @{
        kConfigInputMode: @(1),  // 中文模式
        kConfigCandidatesPerPage: @(5),
        kConfigFuzzyEnabled: @(NO),
        kConfigFuzzyZ_ZH: @(NO),
        kConfigFuzzyC_CH: @(NO),
        kConfigFuzzyS_SH: @(NO),
        kConfigFuzzyN_L: @(NO),
        kConfigFuzzyF_H: @(NO),
        kConfigFuzzyAn_Ang: @(NO),
        kConfigFuzzyEn_Eng: @(NO),
        kConfigFuzzyIn_In: @(NO),
        kConfigRememberMode: @(YES),
        kConfigSwitchKey: @"Shift",
    };
}

#pragma mark - 读取方法

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = _cache[key];
    if (value && [value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return defaultValue;
}

- (NSInteger)integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = _cache[key];
    if (value && [value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return defaultValue;
}

- (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    id value = _cache[key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return defaultValue;
}

- (id)objectForKey:(NSString *)key defaultValue:(id)defaultValue {
    id value = _cache[key];
    return value ?: defaultValue;
}

#pragma mark - 写入方法

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    _cache[key] = @(value);
    [_defaults setBool:value forKey:key];
    [self notifyObservers];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    _cache[key] = @(value);
    [_defaults setInteger:value forKey:key];
    [self notifyObservers];
}

- (void)setString:(NSString *)value forKey:(NSString *)key {
    _cache[key] = value;
    [_defaults setObject:value forKey:key];
    [self notifyObservers];
}

- (void)setObject:(id)value forKey:(NSString *)key {
    _cache[key] = value;
    [_defaults setObject:value forKey:key];
    [self notifyObservers];
}

#pragma mark - 观察�?

- (void)addChangeObserver:(id)observer selector:(SEL)selector {
    NSValue *observerValue = [NSValue valueWithNonretainedObject:observer];
    NSDictionary *entry = @{
        @"observer": observerValue,
        @"selector": NSStringFromSelector(selector),
    };
    [_observers addObject:entry];
}

- (void)removeChangeObserver:(id)observer {
    NSValue *observerValue = [NSValue valueWithNonretainedObject:observer];
    NSMutableArray *toRemove = [NSMutableArray array];
    
    for (NSDictionary *entry in _observers) {
        if ([entry[@"observer"] isEqualToValue:observerValue]) {
            [toRemove addObject:entry];
        }
    }
    
    [_observers removeObjectsInArray:toRemove];
}

- (void)notifyObservers {
    for (NSDictionary *entry in _observers) {
        id observer = [entry[@"observer"] nonretainedObjectValue];
        SEL selector = NSSelectorFromString(entry[@"selector"]);
        
        if (observer && [observer respondsToSelector:selector]) {
            [observer performSelector:selector withObject:self];
        }
    }
}

@end
