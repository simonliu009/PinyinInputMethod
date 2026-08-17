/*
 * PinyinInputMethod - macOS 拼音输入法
 * main.m - 程序入口
 *
 * 基于 Input Method Kit 框架的拼音输入法主入口
 */

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

// 输入法连接名称，需与 Info.plist 中 InputMethodConnectionName 保持一致
static NSString * const kConnectionName = @"com.ximeng.inputmethod.connection";
// 输入法 Bundle Identifier，需与 Info.plist 中保持一致
static NSString * const kInputMethodBundleID = @"com.ximeng.inputmethod";

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // 连接输入法服务器
        IMKServer *server = [[IMKServer alloc] initWithName:kConnectionName
                                          bundleIdentifier:kInputMethodBundleID];
        
        if (!server) {
            NSLog(@"[PinyinInputMethod] 错误：无法创建 IMKServer");
            return 1;
        }
        
        NSLog(@"[PinyinInputMethod] 输入法服务器已启动");
        
        // 启动主事件循环
        return NSApplicationMain(argc, (const char **)argv);
    }
}
