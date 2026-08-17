/*
 * PinyinInputMethod - macOS 拼音输入法
 * main.m - 程序入口
 *
 * 基于 Input Method Kit 框架的拼音输入法主入口
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

// 输入法 Bundle Identifier，需与 Info.plist 中保持一致
static NSString * const kInputMethodBundleID = @"com.ximeng.inputmethod";

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // 获取输入法 Bundle
        NSBundle *bundle = [NSBundle bundleForClass:[NSObject class]];
        
        // 连接输入法服务器
        // IMKServer 是 Input Method Kit 的核心类，负责与系统输入法框架通信
        IMKServer *server = [[IMKServer alloc] initWithName:kInputMethodBundleID
                                          bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        
        if (!server) {
            NSLog(@"[PinyinInputMethod] 错误：无法创建 IMKServer");
            return 1;
        }
        
        NSLog(@"[PinyinInputMethod] 输入法服务器已启动");
        
        // 启动主事件循环
        return NSApplicationMain(argc, (const char **)argv);
    }
}
