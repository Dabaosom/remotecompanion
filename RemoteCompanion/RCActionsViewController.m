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

@interface RCActionsViewController () <UITableViewDragDelegate, UITableViewDropDelegate>
@property (nonatomic, strong) NSString *triggerKey;
@property (nonatomic, strong) NSMutableArray *actions;
@end

@implementation RCActionsViewController

// Helper methods moved to RCConfigManager for consistency
- (NSString *)displayNameForCommand:(id)cmd {
    return [[RCConfigManager sharedManager] nameForCommand:cmd truncate:YES];
}

- (NSString *)iconForCommand:(id)cmd {
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
    
    // Non-editing mode to allow swipe actions
    self.tableView.editing = NO;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.dragInteractionEnabled = YES;
    self.tableView.dragDelegate = self;
    self.tableView.dropDelegate = self;
    
    // Deletion is handled via swipe actions (trailingSwipeActionsConfigurationForRowAtIndexPath)
    
    self.navigationItem.rightBarButtonItems = @[addButton];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ActionCell"];
    self.tableView.rowHeight = 70; // Fixed height as in V2.1.2
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
            inputVC.promptMessage = @"Enter terminal command";
            inputVC.showRootToggle = YES;
            inputVC.initialText = @"";
            
            __weak typeof(inputVC) weakInputVC = inputVC;
            inputVC.onComplete = ^(NSString *text) {
                if (text.length > 0) {
                    NSString *prefix = weakInputVC.isRootToggled ? @"root" : @"exec";
                    [self.actions addObject:[NSString stringWithFormat:@"%@ %@", prefix, text]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            };
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inputVC];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:nil];
            });

        } else if ([action isEqualToString:@"__CUSTOM_ROOT__"]) {
            // Re-use terminal command but fixed as root
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Root Command" 
                message:@"Enter terminal command (runs as root)" 
                preferredStyle:UIAlertControllerStyleAlert];
                
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"ldrestart";
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
            }];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull alertAction) {
                NSString *input = alert.textFields.firstObject.text;
                if (input.length > 0) {
                    [self.actions addObject:[NSString stringWithFormat:@"root %@", input]];
                    [self saveActions];
                    [self.tableView reloadData];
                }
            }]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
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
        } else if ([action isEqualToString:@"__IF_CONDITION__"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentIfConditionPickerForIndex:NSNotFound];
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

- (NSString *)actionTypeForItem:(id)item {
    if (![item isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [[((NSDictionary *)item)[@"type"] description] lowercaseString];
}

- (BOOL)isIfActionItem:(id)item {
    return [[self actionTypeForItem:item] isEqualToString:@"if"];
}

- (BOOL)isEndIfActionItem:(id)item {
    NSString *type = [self actionTypeForItem:item];
    return [type isEqualToString:@"end_if"] || [type isEqualToString:@"end"];
}

- (NSInteger)matchingEndIndexForIfAtIndex:(NSInteger)startIndex {
    if (startIndex < 0 || startIndex >= (NSInteger)self.actions.count) {
        return NSNotFound;
    }
    if (![self isIfActionItem:self.actions[startIndex]]) {
        return NSNotFound;
    }
    
    NSInteger depth = 0;
    for (NSInteger idx = startIndex; idx < (NSInteger)self.actions.count; idx++) {
        id item = self.actions[idx];
        if ([self isIfActionItem:item]) {
            depth++;
        } else if ([self isEndIfActionItem:item]) {
            depth--;
            if (depth == 0) {
                return idx;
            }
        }
    }
    return NSNotFound;
}

- (NSInteger)matchingIfIndexForEndAtIndex:(NSInteger)endIndex {
    if (endIndex < 0 || endIndex >= (NSInteger)self.actions.count) {
        return NSNotFound;
    }
    if (![self isEndIfActionItem:self.actions[endIndex]]) {
        return NSNotFound;
    }
    
    NSInteger depth = 0;
    for (NSInteger idx = endIndex; idx >= 0; idx--) {
        id item = self.actions[idx];
        if ([self isEndIfActionItem:item]) {
            depth++;
        } else if ([self isIfActionItem:item]) {
            depth--;
            if (depth == 0) {
                return idx;
            }
        }
    }
    return NSNotFound;
}

- (NSRange)ifBlockRangeForIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.actions.count) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    id item = self.actions[index];
    if ([self isIfActionItem:item]) {
        NSInteger endIndex = [self matchingEndIndexForIfAtIndex:index];
        if (endIndex != NSNotFound) {
            return NSMakeRange(index, endIndex - index + 1);
        }
    } else if ([self isEndIfActionItem:item]) {
        NSInteger startIndex = [self matchingIfIndexForEndAtIndex:index];
        if (startIndex != NSNotFound) {
            return NSMakeRange(startIndex, index - startIndex + 1);
        }
    }
    
    return NSMakeRange(index, 1);
}

- (NSInteger)indentationLevelForRow:(NSInteger)row {
    NSInteger depth = 0;
    for (NSInteger idx = 0; idx < row; idx++) {
        id item = self.actions[idx];
        if ([self isIfActionItem:item]) {
            depth++;
        } else if ([self isEndIfActionItem:item]) {
            depth = MAX(depth - 1, 0);
        }
    }
    
    id current = self.actions[row];
    if ([self isEndIfActionItem:current]) {
        return MAX(depth - 1, 0);
    }
    return depth;
}

- (NSArray<NSDictionary *> *)ifConditionDefinitions {
    return @[
        @{
            @"key": @"lock",
            @"title": @"Lock Status",
            @"values": @[
                @{ @"value": @"LOCKED", @"title": @"Locked" },
                @{ @"value": @"UNLOCKED", @"title": @"Unlocked" }
            ]
        },
        @{
            @"key": @"player",
            @"title": @"Player Status",
            @"values": @[
                @{ @"value": @"PLAYING", @"title": @"Playing" },
                @{ @"value": @"PAUSED", @"title": @"Paused" },
                @{ @"value": @"STOPPED", @"title": @"Stopped" }
            ]
        },
        @{
            @"key": @"wifi",
            @"title": @"Wi-Fi",
            @"values": @[
                @{ @"value": @"ON", @"title": @"On" },
                @{ @"value": @"OFF", @"title": @"Off" }
            ]
        },
        @{
            @"key": @"bluetooth",
            @"title": @"Bluetooth",
            @"values": @[
                @{ @"value": @"ON", @"title": @"On" },
                @{ @"value": @"OFF", @"title": @"Off" }
            ]
        },
        @{
            @"key": @"airplane",
            @"title": @"Airplane Mode",
            @"values": @[
                @{ @"value": @"ON", @"title": @"On" },
                @{ @"value": @"OFF", @"title": @"Off" }
            ]
        },
        @{
            @"key": @"silent_vibration",
            @"title": @"Silent Vibration",
            @"values": @[
                @{ @"value": @"ON", @"title": @"On" },
                @{ @"value": @"OFF", @"title": @"Off" }
            ]
        },
        @{
            @"key": @"ring_vibration",
            @"title": @"Ring Vibration",
            @"values": @[
                @{ @"value": @"ON", @"title": @"On" },
                @{ @"value": @"OFF", @"title": @"Off" }
            ]
        }
    ];
}

- (void)configurePopoverSourceForAlert:(UIAlertController *)alert {
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
}

- (NSDictionary *)buildIfActionWithCondition:(NSDictionary *)condition expectedValue:(NSDictionary *)expectedValue {
    return @{
        @"type": @"if",
        @"conditionKey": condition[@"key"] ?: @"",
        @"conditionTitle": condition[@"title"] ?: @"Condition",
        @"expectedValue": expectedValue[@"value"] ?: @"",
        @"expectedTitle": expectedValue[@"title"] ?: @"Value"
    };
}

- (void)presentIfValuePickerForCondition:(NSDictionary *)condition existingIndex:(NSInteger)index {
    NSArray *values = condition[@"values"] ?: @[];
    NSString *title = [NSString stringWithFormat:@"%@ is...", condition[@"title"] ?: @"Condition"];
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:title
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *value in values) {
        [picker addAction:[UIAlertAction actionWithTitle:value[@"title"]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction * _Nonnull action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            NSDictionary *ifAction = [strongSelf buildIfActionWithCondition:condition expectedValue:value];
            if (index != NSNotFound && index >= 0 && index < (NSInteger)strongSelf.actions.count) {
                strongSelf.actions[index] = ifAction;
            } else {
                [strongSelf.actions addObject:ifAction];
                [strongSelf.actions addObject:@{ @"type": @"end_if" }];
            }
            [strongSelf saveActions];
            [strongSelf.tableView reloadData];
        }]];
    }
    
    [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self configurePopoverSourceForAlert:picker];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)presentIfConditionPickerForIndex:(NSInteger)index {
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"If Condition"
                                                                     message:@"Choose a status to evaluate"
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    
    for (NSDictionary *condition in [self ifConditionDefinitions]) {
        [picker addAction:[UIAlertAction actionWithTitle:condition[@"title"]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction * _Nonnull action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf presentIfValuePickerForCondition:condition existingIndex:index];
        }]];
    }
    
    [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self configurePopoverSourceForAlert:picker];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)moveActionFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    if (sourceIndex < 0 || sourceIndex >= (NSInteger)self.actions.count) {
        return;
    }
    
    NSRange rangeToMove = [self ifBlockRangeForIndex:sourceIndex];
    if (rangeToMove.location == NSNotFound || rangeToMove.length == 0) {
        return;
    }
    
    if (destinationIndex > (NSInteger)self.actions.count) {
        destinationIndex = self.actions.count;
    }
    
    if (destinationIndex >= (NSInteger)rangeToMove.location &&
        destinationIndex <= (NSInteger)(rangeToMove.location + rangeToMove.length)) {
        return;
    }
    
    NSArray *itemsToMove = [self.actions subarrayWithRange:rangeToMove];
    [self.actions removeObjectsInRange:rangeToMove];
    
    if (destinationIndex > (NSInteger)rangeToMove.location) {
        destinationIndex -= rangeToMove.length;
    }
    
    destinationIndex = MAX(0, MIN(destinationIndex, (NSInteger)self.actions.count));
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, itemsToMove.count)];
    [self.actions insertObjects:itemsToMove atIndexes:indexes];
    
    [self saveActions];
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id actionData = self.actions[indexPath.row];
    
    if ([actionData isKindOfClass:[NSDictionary class]]) {
        if ([self isIfActionItem:actionData]) {
            [self presentIfConditionPickerForIndex:indexPath.row];
        }
        return;
    }
    
    NSString *currentAction = (NSString *)actionData;
    
    if ([currentAction hasPrefix:@"exec "] || [currentAction hasPrefix:@"root "]) {
        // Edit Terminal Command
        BOOL isRoot = [currentAction hasPrefix:@"root "];
        NSString *currentCommand = [currentAction substringFromIndex:5];
        
        RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
        inputVC.promptTitle = @"Edit Command";
        inputVC.promptMessage = @"Update your terminal command";
        inputVC.initialText = currentCommand;
        inputVC.showRootToggle = YES;
        inputVC.isRootToggled = isRoot;
        
        __weak typeof(inputVC) weakInputVC = inputVC;
        inputVC.onComplete = ^(NSString *text) {
            if (text.length > 0) {
                NSString *prefix = weakInputVC.isRootToggled ? @"root" : @"exec";
                self.actions[indexPath.row] = [NSString stringWithFormat:@"%@ %@", prefix, text];
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
        // Edit Lua Script
        int prefixLength = [currentAction hasPrefix:@"lua_eval "] ? 9 : 4;
        NSString *currentCode = [currentAction substringFromIndex:prefixLength];
        
        RCTextInputViewController *inputVC = [[RCTextInputViewController alloc] init];
        inputVC.promptTitle = @"Edit Lua Script";
        inputVC.promptMessage = @"Update your Lua code";
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
    // Use Subtitle style
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ActionCell"];
    }

    id actionItem = _actions[indexPath.row];
    NSString *cleanName = [self displayNameForCommand:actionItem];
    NSString *subtitle = nil;
    NSInteger indentationLevel = [self indentationLevelForRow:indexPath.row];

    cell.indentationWidth = 18.0f;
    cell.indentationLevel = indentationLevel;

    if ([actionItem isKindOfClass:[NSDictionary class]]) {
        cell.textLabel.text = cleanName;
        cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        cell.textLabel.textColor = [self isEndIfActionItem:actionItem] ? [UIColor secondaryLabelColor] : [UIColor labelColor];
        cell.detailTextLabel.text = nil;
        
        cell.imageView.image = [UIImage systemImageNamed:[self iconForCommand:actionItem]];
        cell.imageView.tintColor = [self isEndIfActionItem:actionItem] ? [UIColor tertiaryLabelColor] : [UIColor systemGrayColor];
        
        UIImageView *handleView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal"]];
        handleView.tintColor = [UIColor systemGray3Color];
        cell.accessoryView = handleView;
        return cell;
    }

    NSString *action = (NSString *)actionItem;

    // Logic to separate "Type" from "Value"
    if ([action hasPrefix:@"exec "]) {
        cell.textLabel.text = @"Terminal Command";
        subtitle = [action substringFromIndex:5];
    } else if ([action hasPrefix:@"root "]) {
        cell.textLabel.text = @"Root Command";
        subtitle = [action substringFromIndex:5];
    } else if ([action hasPrefix:@"Lua "] || [action hasPrefix:@"lua "]) {
        cell.textLabel.text = @"Lua Script";
        subtitle = [action hasPrefix:@"Lua "] ? [action substringFromIndex:4] : [action substringFromIndex:4];
    } else if ([action hasPrefix:@"delay "]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Wait %@s", [action substringFromIndex:6]];
        subtitle = [NSString stringWithFormat:@"%@ seconds", [action substringFromIndex:6]];
    } else if ([action hasPrefix:@"shortcut:"]) {
        cell.textLabel.text = cleanName;
        subtitle = @"Siri Shortcut";
    } else if ([action hasPrefix:@"uiopen "]) {
        cell.textLabel.text = cleanName;
        subtitle = @"Application";
    } else if ([action hasPrefix:@"airplay connect "]) {
        cell.textLabel.text = cleanName;
        subtitle = @"AirPlay Device";
    } else if ([action hasPrefix:@"bt connect "] || [action hasPrefix:@"bluetooth connect "]) {
        cell.textLabel.text = cleanName;
        subtitle = @"Bluetooth Device";
    } else if ([action hasPrefix:@"bt disconnect "] || [action hasPrefix:@"bluetooth disconnect "]) {
        cell.textLabel.text = cleanName;
        subtitle = nil;
    } else if ([action hasPrefix:@"airplay disconnect"]) {
        cell.textLabel.text = cleanName;
        subtitle = nil;
    } else if ([action isEqualToString:@"ldrestart"] || [action isEqualToString:@"userspace-reboot"] || [action isEqualToString:@"uicache"] || [action isEqualToString:@"player status"]) {
        cell.textLabel.text = cleanName;
        subtitle = nil;
    } else {
        cell.textLabel.text = cleanName;
        subtitle = nil;
    }

    cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    cell.textLabel.textColor = [UIColor labelColor];

    if (subtitle) {
        cell.detailTextLabel.text = subtitle;
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];

        // Use monospace for code-like things
        if ([action hasPrefix:@"exec "] || [action hasPrefix:@"root "] || [action hasPrefix:@"Lua "] || [action hasPrefix:@"lua "]) {
            cell.detailTextLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
            cell.detailTextLabel.numberOfLines = 1;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        } else {
             cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        }
    } else {
        cell.detailTextLabel.text = nil;
    }

    NSString *iconName = [self iconForCommand:action];
    if ([iconName hasPrefix:@"USER_APP:"]) {
        NSString *bundleId = [iconName substringFromIndex:9];
        cell.imageView.image = [UIImage _applicationIconImageForBundleIdentifier:bundleId format:0 scale:[UIScreen mainScreen].scale];
        cell.imageView.tintColor = nil;
    } else {
        cell.imageView.image = [UIImage systemImageNamed:iconName];
        cell.imageView.tintColor = [UIColor systemGrayColor];
    }

    // Custom reorder handle (since editing = NO)
    UIImageView *handleView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal"]];
    handleView.tintColor = [UIColor systemGray3Color];
    cell.accessoryView = handleView;
    return cell;
}

#pragma mark - UITableViewDragDelegate

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    id action = self.actions[indexPath.row];
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:@"rc-action"];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    dragItem.localObject = action;
    return @[dragItem];
}

#pragma mark - UITableViewDropDelegate

- (UITableViewDropProposal *)tableView:(UITableView *)tableView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath {
    if (tableView.hasActiveDrag) {
        return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationMove intent:UITableViewDropIntentInsertAtDestinationIndexPath];
    }
    return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
}

- (void)tableView:(UITableView *)tableView performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
    NSIndexPath *destinationIndexPath = coordinator.destinationIndexPath;
    NSInteger destinationIndex = destinationIndexPath ? destinationIndexPath.row : self.actions.count;
    
    for (id<UITableViewDropItem> item in coordinator.items) {
        if (!item.sourceIndexPath) continue;
        
        NSInteger sourceIndex = item.sourceIndexPath.row;
        id sourceItem = (sourceIndex >= 0 && sourceIndex < (NSInteger)self.actions.count) ? self.actions[sourceIndex] : nil;
        
        if (destinationIndexPath &&
            destinationIndex >= 0 &&
            destinationIndex < (NSInteger)self.actions.count &&
            [self isIfActionItem:self.actions[destinationIndex]] &&
            ![self isIfActionItem:sourceItem] &&
            ![self isEndIfActionItem:sourceItem]) {
            // UX: dropping onto an If header should place a normal action inside that block.
            destinationIndex += 1;
        }
        
        [self moveActionFromIndex:sourceIndex toIndex:destinationIndex];
        
        if (self.actions.count > 0) {
            NSInteger finalRow = MIN(MAX(destinationIndex, 0), (NSInteger)self.actions.count - 1);
            [coordinator dropItem:item.dragItem toRowAtIndexPath:[NSIndexPath indexPathForRow:finalRow inSection:0]];
        }
        break;
    }
}

// Swipe Actions
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSRange rangeToDelete = [self ifBlockRangeForIndex:indexPath.row];
    BOOL isBlockDelete = rangeToDelete.length > 1;
    
    UIContextualAction *deleteAction = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive
        title:isBlockDelete ? @"Delete Block" : @"Delete"
        handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            if (rangeToDelete.location != NSNotFound && rangeToDelete.length > 0 && NSMaxRange(rangeToDelete) <= self.actions.count) {
                [self.actions removeObjectsInRange:rangeToDelete];
            } else if (indexPath.row < self.actions.count) {
                [self.actions removeObjectAtIndex:indexPath.row];
            }
            [self saveActions];
            [tableView reloadData];
            completionHandler(YES);
        }];

    deleteAction.image = [UIImage systemImageNamed:@"trash.fill"];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

// Reordering (legacy but kept for logic reference, though drag/drop is primary now)
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [self moveActionFromIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

// Deletion (legacy - leading/trailing swipe actions are preferred now)
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone; // Prevent standard delete indicator
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


@end
