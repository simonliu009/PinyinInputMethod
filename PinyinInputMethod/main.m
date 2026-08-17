/*
 * PinyinInputMethod - macOS 拼音输入�?
 * main.m - 程序入口
 *
 * 基于 Input Method Kit 框架的拼音输入法主入�?
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

// 输入�?Bundle Identifier，需�?Info.plist 中保持一�?
static NSString * const kInputMethodBundleID = @"com.ximeng.inputmethod";

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // 获取输入�?Bundle
        NSBundle *bundle = [NSBundle bundleForClass:[NSObject class]];
        
        // 连接输入法服务器
        // IMKServer �?Input Method Kit 的核心类，负责与系统输入法框架通信
        IMKServer *server = [[IMKServer alloc] initWithName:kInputMethodBundleID
                                          bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        
        if (!server) {
            NSLog(@"[PinyinInputMethod] 错误：无法创�?IMKServer");
            return 1;
        }
        
        NSLog(@"[PinyinInputMethod] 输入法服务器已启�?);
        
        // 启动主事件循�?
        return NSApplicationMain(argc, (const char **)argv);
    }
}
