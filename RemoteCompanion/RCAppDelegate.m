#import "RCAppDelegate.h"
#import "RCTriggersViewController.h"

#define RCLog(...) do { \
    NSString *msg__ = [NSString stringWithFormat:__VA_ARGS__]; \
    NSFileHandle *fh__ = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Documents/rclog.txt"]; \
    if (!fh__) { \
        [@"" writeToFile:@"/var/mobile/Documents/rclog.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil]; \
        fh__ = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Documents/rclog.txt"]; \
    } \
    [fh__ seekToEndOfFile]; \
    NSString *line__ = [NSString stringWithFormat:@"%@\n", msg__]; \
    [fh__ writeData:[line__ dataUsingEncoding:NSUTF8StringEncoding]]; \
    [fh__ closeFile]; \
    NSLog(@"%@", msg__); \
} while(0)

@implementation RCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [@"--- APP LAUNCH ---" writeToFile:@"/var/mobile/Documents/rclog.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    RCLog(@"App launched! starting didFinishLaunchingWithOptions");
    
    @try {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        RCLog(@"Window created");
        
        RCTriggersViewController *triggersVC = [[RCTriggersViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
        RCLog(@"RCTriggersViewController created");
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:triggersVC];
        RCLog(@"Nav created");
        
        self.window.rootViewController = nav;
        [self.window makeKeyAndVisible];
        RCLog(@"makeKeyAndVisible done");
    } @catch (NSException *exception) {
        RCLog(@"CRASH: %@ - %@", exception.name, exception.reason);
    }
    
    return YES;
}

@end
