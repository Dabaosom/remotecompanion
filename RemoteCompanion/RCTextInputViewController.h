#import <UIKit/UIKit.h>

@interface RCTextInputViewController : UIViewController

@property (nonatomic, copy) NSString *promptTitle;
@property (nonatomic, copy) NSString *promptMessage;
@property (nonatomic, copy) NSString *initialText;
@property (nonatomic, assign) BOOL showRootToggle;
@property (nonatomic, assign) BOOL isRootToggled;

@property (nonatomic, copy) void (^onComplete)(NSString *text);

@end
