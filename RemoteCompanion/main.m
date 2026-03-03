#import <UIKit/UIKit.h>
#import "RCAppDelegate.h"

int main(int argc, char *argv[]) {
    @try {
        @autoreleasepool {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([RCAppDelegate class]));
        }
    } @catch (NSException *exception) {
        NSFileHandle *fh__ = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Documents/rclog.txt"];
        if (!fh__) {
            [@"" writeToFile:@"/var/mobile/Documents/rclog.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            fh__ = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Documents/rclog.txt"];
        }
        [fh__ seekToEndOfFile];
        NSString *line__ = [NSString stringWithFormat:@"MAIN CRASH: %@ - %@\n%@\n", exception.name, exception.reason, exception.callStackSymbols];
        [fh__ writeData:[line__ dataUsingEncoding:NSUTF8StringEncoding]];
        [fh__ closeFile];
        @throw;
    }
}
