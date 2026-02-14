#import "RCActionsViewController.h"
#import "RCConfigManager.h"
#import "RCActionPickerViewController.h"
#import "RCShortcutPickerViewController.h"
#import "RCAppPickerViewController.h"
#import "RCTextInputViewController.h"
#import "RCServerClient.h"

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface RCActionsViewController ()
@property (nonatomic, strong) NSString *triggerKey;
@property (nonatomic, strong) NSMutableArray<NSString *> *actions;
@end

@implementation RCActionsViewController

// Helper methods moved to RCConfigManager for consistency
- (NSString *)displayNameForCommand:(NSString *)cmd {
    return [[RCConfigManager sharedManager] nameForCommand:cmd truncate:YES];
}

- (NSString *)iconForCommand:(NSString *)cmd {
    return [[RCConfigManager sharedManager] iconForCommand:cmd];
}

- (instancetype)initWithTriggerKey:(NSString *)triggerKey {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _triggerKey = triggerKey;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Elegant grey tint
    self.navigationController.navigationBar.tintColor = [UIColor labelColor];
    
    self.title = [[RCConfigManager sharedManager] displayNameForTrigger:_triggerKey];
    
    // Setup Navigation Items
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] 
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
        target:self 
        action:@selector(addAction)];
        
    self.navigationItem.rightBarButtonItem = addButton;

    // Add tap gesture to title if it's an NFC trigger
    if ([_triggerKey hasPrefix:@"nfc_"]) {
        UITapGestureRecognizer *titleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(renameTrigger)];
        
        // Create a custom title view to accept interactions
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = self.title;
        titleLabel.font = [UIFont boldSystemFontOfSize:17];
        titleLabel.userInteractionEnabled = YES;
        [titleLabel addGestureRecognizer:titleTap];
        
        self.navigationItem.titleView = titleLabel;
    }
    
    // Enable Large Titles
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Load actions
    _actions = [[[RCConfigManager sharedManager] actionsForTrigger:_triggerKey] mutableCopy];
    
    // Default to NOT editing to show clean UI
    self.tableView.editing = NO;
    self.navigationItem.rightBarButtonItems = @[addButton, self.editButtonItem];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ActionCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 70;
}

- (void)renameTrigger {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename Tag" 
                                                                   message:@"Enter a new name for this NFC tag:" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"My Tag";
        textField.text = self.title;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newName = alert.textFields.firstObject.text;
        if (newName.length > 0) {
            [[RCConfigManager sharedManager] renameTrigger:self.triggerKey toName:newName];
            self.title = newName;
            
            // Update custom title view text
            if ([self.navigationItem.titleView isKindOfClass:[UILabel class]]) {
                ((UILabel *)self.navigationItem.titleView).text = newName;
                [self.navigationItem.titleView sizeToFit];
            }
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addAction {
    RCActionPickerViewController *picker = [[RCActionPickerViewController alloc] init];
    picker.onActionSelected = ^(NSString *action) {
        if ([action isEqualToString:@"__SHORTCUT_PICKER__"]) {
            // Present Shortcut Picker
            RCShortcutPickerViewController *vc = [[RCShortcutPickerViewController alloc] init];
            vc.onShortcutSelected = ^(NSString *shortcutName) {
                [self.actions addObject:[NSString stringWithFormat:@"shortcut:%@", shortcutName]];
                [self saveActions];
                [self.tableView reloadData];
                // Dismiss picker
                 [self dismissViewControllerAnimated:YES completion:nil];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });
            
        } else if ([action isEqualToString:@"__CUSTOM__"]) {
            // Show custom text input for command
            RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
            inputVC.promptTitle = @"Terminal Command";
            inputVC.promptMessage = @"Enter terminal command (runs as mobile user)";
            inputVC.onComplete = ^(NSString *text) {
                if (text.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"exec %@", text]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            };

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });

        } else if ([action isEqualToString:@"__CUSTOM_ROOT__"]) {
            // Show custom text input for root command
            RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
            inputVC.promptTitle = @"Root Command";
            inputVC.promptMessage = @"Enter terminal command (runs as root)";
            inputVC.onComplete = ^(NSString *text) {
                if (text.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"root %@", text]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            };

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });

        } else if ([action isEqualToString:@"__BT_CONNECT__"] || [action isEqualToString:@"__BT_DISCONNECT__"] || [action isEqualToString:@"__AIRPLAY_CONNECT__"]) {
            
            NSString *title = @"Device Name";
            NSString *prefix = @"";
            
            if ([action isEqualToString:@"__BT_CONNECT__"]) {
                title = @"Connect to Bluetooth";
                prefix = @"bt connect ";
            } else if ([action isEqualToString:@"__BT_DISCONNECT__"]) {
                title = @"Disconnect Bluetooth";
                prefix = @"bluetooth disconnect ";
            } else if ([action isEqualToString:@"__AIRPLAY_CONNECT__"]) {
                title = @"Connect AirPlay";
                prefix = @"airplay connect ";
            }

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                message:@"Enter exact device name" 
                preferredStyle:UIAlertControllerStyleAlert];
                
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"My Device";
            }];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull alertAction) {
                NSString *input = alert.textFields.firstObject.text;
                if (input.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"%@%@", prefix, input]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            }]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });

        } else if ([action isEqualToString:@"__DELAY__"]) {
            // Show alert for delay
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Delay" 
                message:@"Enter delay in seconds" 
                preferredStyle:UIAlertControllerStyleAlert];
                
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"1.0";
                textField.keyboardType = UIKeyboardTypeDecimalPad;
            }];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull alertAction) {
                NSString *input = alert.textFields.firstObject.text;
                if (input.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"delay %@", input]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            }]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        } else if ([action isEqualToString:@"__OPEN_APP__"]) {
            RCAppPickerViewController *appPicker = [[RCAppPickerViewController alloc] init];
            appPicker.onAppSelected = ^(NSString *name, NSString *bundleId) {
                // Save as "uiopen <bundleId>"
                [self.actions addObject:[NSString stringWithFormat:@"uiopen %@", bundleId]];
                [self saveActions];
                [self.tableView reloadData];
            };
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:appPicker];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });
        } else if ([action isEqualToString:@"__LUA_SCRIPT__"]) {
            RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
            inputVC.promptTitle = @"Lua Script";
            inputVC.promptMessage = @"Enter Lua code to execute";
            inputVC.initialText = @"";
            inputVC.onComplete = ^(NSString *text) {
                if (text.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"Lua %@", text]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            };
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });
        } else {
            [self.actions addObject:action];
            [self saveActions];
            [self.tableView reloadData];
        }
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)saveActions {
    [[RCConfigManager sharedManager] setActions:_actions forTrigger:_triggerKey];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *currentAction = self.actions[indexPath.row];
    
    if ([currentAction hasPrefix:@"exec "]) {
        // Edit Custom Command
        NSString *currentCommand = [currentAction substringFromIndex:5];
        
        RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
        inputVC.promptTitle = @"Edit Command";
        inputVC.promptMessage = @"Update your terminal command";
        inputVC.initialText = currentCommand;
        inputVC.onComplete = ^(NSString *text) {
            if (text.length > 0) {
                self.actions[indexPath.row] = [NSString stringWithFormat:@"exec %@", text];
                [self saveActions];
                [self.tableView reloadData];
            }
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];
        [self presentViewController:nav animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"set-vol "] || [currentAction hasPrefix:@"brightness "]) {
        // Edit Volume/Brightness
        BOOL isVolume = [currentAction hasPrefix:@"set-vol "];
        NSString *title = isVolume ? @"Edit Volume" : @"Edit Brightness";
        NSString *prefix = isVolume ? @"set-vol " : @"brightness ";
        NSString *currentValue = [currentAction substringFromIndex:prefix.length];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                       message:@"Enter a value (0-100)" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.text = currentValue;
            textField.textAlignment = NSTextAlignmentCenter;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            int val = [textField.text intValue];
            if (val < 0) val = 0;
            if (val > 100) val = 100;
            
            self.actions[indexPath.row] = [NSString stringWithFormat:@"%@%d", prefix, val];
            [self saveActions];
            [self.tableView reloadData];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"Lua "] || [currentAction hasPrefix:@"lua_eval "] || [currentAction hasPrefix:@"lua "]) {
        // Edit Lua Script (Direct or File)
        BOOL isDirect = [currentAction hasPrefix:@"Lua "] || [currentAction hasPrefix:@"lua_eval "];
        int prefixLength = 0;
        if ([currentAction hasPrefix:@"Lua "]) prefixLength = 4;
        else if ([currentAction hasPrefix:@"lua_eval "]) prefixLength = 9;
        else prefixLength = 4;

        NSString *currentCode = [currentAction substringFromIndex:prefixLength];
        
        RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
        inputVC.promptTitle = @"Edit Lua Script";
        inputVC.promptMessage = isDirect ? @"Update your Lua code" : @"Update script path (convert to direct code if desired)";
        inputVC.initialText = currentCode;
        inputVC.onComplete = ^(NSString *text) {
            if (text.length > 0) {
                // We always save as Lua (direct) when editing
                self.actions[indexPath.row] = [NSString stringWithFormat:@"Lua %@", text];
                [self saveActions];
                [self.tableView reloadData];
            }
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];
        [self presentViewController:nav animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"root "]) {
        // Edit Root Command
        NSString *currentCommand = [currentAction substringFromIndex:5];

        RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
        inputVC.promptTitle = @"Edit Root Command";
        inputVC.promptMessage = @"Update your terminal command (runs as root)";
        inputVC.initialText = currentCommand;
        inputVC.onComplete = ^(NSString *text) {
            if (text.length > 0) {
                self.actions[indexPath.row] = [NSString stringWithFormat:@"root %@", text];
                [self saveActions];
                [self.tableView reloadData];
            }
        };

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];
        [self presentViewController:nav animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"delay "]) {
        // Edit Delay
        NSString *currentDelay = [currentAction substringFromIndex:6];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Edit Delay"
            message:@"Update delay in seconds"
            preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = currentDelay;
            textField.placeholder = @"1.0";
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *input = alert.textFields.firstObject.text;
            if (input.length > 0) {
                self.actions[indexPath.row] = [NSString stringWithFormat:@"delay %@", input];
                [self saveActions];
                [self.tableView reloadData];
            }
        }]];

        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // Generic edit for other commands - show alert with current command
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Edit Action"
            message:@"Modify the command"
            preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = currentAction;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *input = alert.textFields.firstObject.text;
            if (input.length > 0) {
                self.actions[indexPath.row] = input;
                [self saveActions];
                [self.tableView reloadData];
            }
        }]];

        [self presentViewController:alert animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"shortcut:"]) {
        // Edit Shortcut
        RCShortcutPickerViewController *shortcutPicker = [[RCShortcutPickerViewController alloc] init];
        shortcutPicker.onShortcutSelected = ^(NSString *name) {
            self.actions[indexPath.row] = [NSString stringWithFormat:@"shortcut:%@", name];
            [self saveActions];
            [self.tableView reloadData];
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:shortcutPicker];
        [self presentViewController:nav animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"uiopen "]) {
        // Edit App
        RCAppPickerViewController *appPicker = [[RCAppPickerViewController alloc] init];
        appPicker.onAppSelected = ^(NSString *name, NSString *bundleId) {
            self.actions[indexPath.row] = [NSString stringWithFormat:@"uiopen %@", bundleId];
            [self saveActions];
            [self.tableView reloadData];
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:appPicker];
        [self presentViewController:nav animated:YES completion:nil];
    } else if ([currentAction hasPrefix:@"airplay connect "] || [currentAction hasPrefix:@"airplay-connect "]) {
        [self editAirPlayConnectAtIndex:indexPath.row];
    } else if ([currentAction hasPrefix:@"bt connect "] || [currentAction hasPrefix:@"bluetooth connect "] || [currentAction hasPrefix:@"bt-connect "]) {
        [self editBluetoothConnectAtIndex:indexPath.row isDisconnect:NO];
    } else if ([currentAction hasPrefix:@"bt disconnect "] || [currentAction hasPrefix:@"bluetooth disconnect "] || [currentAction hasPrefix:@"bt-disconnect "]) {
        [self editBluetoothConnectAtIndex:indexPath.row isDisconnect:YES];
    }
}

- (void)editAirPlayConnectAtIndex:(NSInteger)index {
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"Scanning for devices..." 
                                                                     message:@"Please wait" 
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[RCServerClient sharedClient] executeCommand:@"airplay list" completion:^(NSString * _Nullable output, NSError * _Nullable error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            if (error) {
                UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [errAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:errAlert animated:YES completion:nil];
                return;
            }
            
            NSArray *lines = [output componentsSeparatedByString:@"\n"];
            NSMutableArray *devices = [NSMutableArray array];
            for (NSString *line in lines) {
                NSString *clean = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (clean.length == 0 || [clean isEqualToString:@"No AirPlay devices found."] || [clean hasPrefix:@"Error:"]) continue;
                if (clean.length < 5) continue;
                NSString *workingLine = clean;
                if ([workingLine hasPrefix:@"* "] || [workingLine hasPrefix:@"  "]) workingLine = [workingLine substringFromIndex:2];
                NSRange openBracket = [workingLine rangeOfString:@" [" options:NSBackwardsSearch];
                NSRange closeBracket = [workingLine rangeOfString:@"]" options:NSBackwardsSearch];
                if (openBracket.location != NSNotFound && closeBracket.location != NSNotFound && closeBracket.location > openBracket.location) {
                    NSString *name = [[workingLine substringToIndex:openBracket.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString *uid = [[workingLine substringWithRange:NSMakeRange(openBracket.location + 2, closeBracket.location - openBracket.location - 2)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    [devices addObject:@{ @"uid": uid, @"name": name }];
                }
            }
            
            if (devices.count == 0) {
                UIAlertController *empty = [UIAlertController alertControllerWithTitle:@"No Devices Found" message:@"Ensure AirPlay devices are reachable." preferredStyle:UIAlertControllerStyleAlert];
                [empty addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:empty animated:YES completion:nil];
                return;
            }
            
            UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"Update AirPlay Device" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            for (NSDictionary *device in devices) {
                [picker addAction:[UIAlertAction actionWithTitle:device[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    self.actions[index] = [NSString stringWithFormat:@"airplay connect %@ # %@", device[@"uid"], device[@"name"]];
                    [self saveActions];
                    [self.tableView reloadData];
                }]];
            }
            [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            picker.popoverPresentationController.sourceView = self.view;
            [self presentViewController:picker animated:YES completion:nil];
        }];
    }];
}

- (void)editBluetoothConnectAtIndex:(NSInteger)index isDisconnect:(BOOL)isDisconnect {
    NSString *promptTitle = isDisconnect ? @"Update Bluetooth Disconnect" : @"Update Bluetooth Connection";
    
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"Fetching paired devices..." 
                                                                     message:@"Please wait" 
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[RCServerClient sharedClient] executeCommand:@"bluetooth list" completion:^(NSString * _Nullable output, NSError * _Nullable error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            if (error || !output) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription ?: @"Failed to fetch devices" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            
            NSArray *lines = [output componentsSeparatedByString:@"\n"];
            NSMutableArray *devices = [NSMutableArray array];
            for (NSString *line in lines) {
                NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (trimmed.length > 0) [devices addObject:trimmed];
            }
            
            if (devices.count == 0) {
                UIAlertController *empty = [UIAlertController alertControllerWithTitle:@"No Devices Found" message:@"Ensure Bluetooth devices are paired." preferredStyle:UIAlertControllerStyleAlert];
                [empty addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:empty animated:YES completion:nil];
                return;
            }
            
            UIAlertController *picker = [UIAlertController alertControllerWithTitle:promptTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            for (NSString *deviceName in devices) {
                [picker addAction:[UIAlertAction actionWithTitle:deviceName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *prefix = isDisconnect ? @"bt disconnect" : @"bt connect";
                    self.actions[index] = [NSString stringWithFormat:@"%@ %@", prefix, deviceName];
                    [self saveActions];
                    [self.tableView reloadData];
                }]];
            }
            [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            picker.popoverPresentationController.sourceView = self.view;
            [self presentViewController:picker animated:YES completion:nil];
        }];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _actions.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_actions.count == 0) return nil;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, tableView.bounds.size.width - 40, 20)];
    label.text = @"ACTION SEQUENCE";
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = [UIColor secondaryLabelColor];
    [headerView addSubview:label];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return _actions.count > 0 ? 40.0f : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (_actions.count == 0) {
        return @"Tap + to add actions. They will run in sequence when the trigger fires.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"ActionCellCustom";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    UILabel *titleLabel;
    UILabel *subtitleLabel;
    UIImageView *iconView;

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.contentView.clipsToBounds = YES;

        iconView = [[UIImageView alloc] init];
        iconView.tag = 100;
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [cell.contentView addSubview:iconView];

        titleLabel = [[UILabel alloc] init];
        titleLabel.tag = 101;
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        titleLabel.textColor = [UIColor labelColor];
        [cell.contentView addSubview:titleLabel];

        subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.tag = 102;
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        subtitleLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        subtitleLabel.textColor = [UIColor secondaryLabelColor];
        subtitleLabel.numberOfLines = 0;
        subtitleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        [cell.contentView addSubview:subtitleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [iconView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [iconView.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [iconView.widthAnchor constraintEqualToConstant:28],
            [iconView.heightAnchor constraintEqualToConstant:28],

            [titleLabel.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:12],
            [titleLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-40],
            [titleLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:10],

            [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
            [subtitleLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
            [subtitleLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-10]
        ]];
    } else {
        iconView = [cell.contentView viewWithTag:100];
        titleLabel = [cell.contentView viewWithTag:101];
        subtitleLabel = [cell.contentView viewWithTag:102];
    }

    NSString *action = _actions[indexPath.row];
    NSString *cleanName = [self displayNameForCommand:action];
    NSString *subtitle = nil;

    // Logic to separate "Type" from "Value"
    if ([action hasPrefix:@"exec "]) {
        titleLabel.text = @"Terminal Command";
        subtitle = [action substringFromIndex:5];
    } else if ([action hasPrefix:@"root "]) {
        titleLabel.text = @"Root Command";
        subtitle = [action substringFromIndex:5];
    } else if ([action hasPrefix:@"Lua "] || [action hasPrefix:@"lua "]) {
        titleLabel.text = @"Lua Script";
        subtitle = [action hasPrefix:@"Lua "] ? [action substringFromIndex:4] : [action substringFromIndex:4];
    } else if ([action hasPrefix:@"delay "]) {
        titleLabel.text = @"Wait";
        subtitle = [NSString stringWithFormat:@"%@ seconds", [action substringFromIndex:6]];
    } else if ([action hasPrefix:@"shortcut:"]) {
        titleLabel.text = cleanName;
        subtitle = @"Siri Shortcut";
    } else if ([action hasPrefix:@"uiopen "]) {
        titleLabel.text = cleanName;
        subtitle = @"Application";
    } else if ([action hasPrefix:@"airplay connect "]) {
        titleLabel.text = cleanName;
        subtitle = @"AirPlay Device";
    } else if ([action hasPrefix:@"bt connect "] || [action hasPrefix:@"bluetooth connect "]) {
        titleLabel.text = cleanName;
        subtitle = @"Bluetooth Device";
    } else if ([action hasPrefix:@"bt disconnect "] || [action hasPrefix:@"bluetooth disconnect "]) {
        titleLabel.text = cleanName;
        subtitle = nil;
    } else if ([action hasPrefix:@"airplay disconnect"]) {
        titleLabel.text = cleanName;
        subtitle = nil;
    } else {
        titleLabel.text = cleanName;
        subtitle = action; // Show raw command
    }

    subtitleLabel.text = subtitle;

    NSString *iconName = [self iconForCommand:action];
    if ([iconName hasPrefix:@"USER_APP:"]) {
        NSString *bundleId = [iconName substringFromIndex:9];
        iconView.image = [UIImage _applicationIconImageForBundleIdentifier:bundleId format:0 scale:[UIScreen mainScreen].scale];
        iconView.tintColor = nil;
    } else {
        iconView.image = [UIImage systemImageNamed:iconName];
        iconView.tintColor = [UIColor systemGrayColor];
    }

    cell.showsReorderControl = YES;
    
    return cell;
}

// Reordering
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSString *action = _actions[sourceIndexPath.row];
    [_actions removeObjectAtIndex:sourceIndexPath.row];
    [_actions insertObject:action atIndex:destinationIndexPath.row];
    [self saveActions];
}

// Deletion
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_actions removeObjectAtIndex:indexPath.row];
        [self saveActions];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
