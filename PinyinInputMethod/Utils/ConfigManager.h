/*
 * PinyinInputMethod - macOS 拼音输入法
 * ConfigManager.h - 配置管理
 *
 * 管理输入法的所有配置项，使用 NSUserDefaults 持久化
 */

#import <Foundation/Foundation.h>

@interface ConfigManager : NSObject

/// 获取单例
+ (instancetype)sharedManager;

/// 加载配置
- (void)loadConfig;

/// 保存配置
- (void)saveConfig;

/// 重置为默认配置
- (void)resetToDefaults;

#pragma mark - 便捷读取方法

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (NSInteger)integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
- (id)objectForKey:(NSString *)key defaultValue:(id)defaultValue;

#pragma mark - 写入方法

- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (void)setObject:(id)value forKey:(NSString *)key;

#pragma mark - 配置变更通知

/// 注册配置变更回调
- (void)addChangeObserver:(id)observer selector:(SEL)selector;

/// 移除配置变更回调
- (void)removeChangeObserver:(id)observer;

@end
