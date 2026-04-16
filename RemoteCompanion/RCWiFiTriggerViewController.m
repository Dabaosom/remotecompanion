#import "RCWiFiTriggerViewController.h"
#import "RCConfigManager.h"
#import "RCActionsViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface RCWiFiTriggerViewController () <UITextFieldDelegate>
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, assign) BOOL isDisconnectTrigger;
@property (nonatomic, strong) UITextField *ssidField;
@property (nonatomic, strong) NSString *triggerKey;
@end

@implementation RCWiFiTriggerViewController

- (instancetype)initWithTriggerKey:(NSString *)triggerKey {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _triggerKey = triggerKey;
    }
    return self;
}

- (instancetype)init {
    return [self initWithTriggerKey:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.triggerKey ? @"Edit WiFi Trigger" : @"New WiFi Trigger";
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(applyTweaks) 
                                                 name:@"RCConfigTweaksChangedNotification" 
                                               object:nil];
    
    [self applyTweaks];
    
    if (self.triggerKey) {
        self.isDisconnectTrigger = [self.triggerKey hasPrefix:@"wifi_disconnect_"];
        self.ssid = [self.triggerKey stringByReplacingOccurrencesOfString:@"wifi_connect_" withString:@""];
        self.ssid = [self.ssid stringByReplacingOccurrencesOfString:@"wifi_disconnect_" withString:@""];
    } else {
        self.ssid = [self currentWiFiSSID] ?: @"";
        self.isDisconnectTrigger = NO;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.triggerKey ? @"Save" : @"Add" style:UIBarButtonItemStyleDone target:self action:@selector(saveTrigger)];
}

- (void)applyTweaks {
    RCConfigManager *cm = [RCConfigManager sharedManager];
    UIColor *bg = [cm tweakColorForKey:@"mainBackground" defaultVal:0.09];
    self.view.backgroundColor = bg;
    self.navigationController.navigationBar.backgroundColor = bg;
    self.tableView.backgroundColor = bg;
    self.tableView.separatorColor = [cm tweakColorForKey:@"separators" defaultVal:0.30];
    [self.tableView reloadData];
}


- (NSString *)currentWiFiSSID {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    return [info objectForKey:@"SSID"];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2; // Connect / Disconnect
    return 1; // SSID Field
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Trigger Event";
    return @"Network Name (SSID)";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TypeCell"];
        }
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Connected to Network";
            cell.accessoryType = !self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"Disconnected from Network";
            cell.accessoryType = self.isDisconnectTrigger ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        if (!self.ssidField) {
            self.ssidField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, tableView.bounds.size.width - 40, 44)];
            self.ssidField.placeholder = @"Enter SSID";
            self.ssidField.text = self.ssid;
            self.ssidField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.ssidField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.ssidField.delegate = self;
            self.ssidField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }
        [cell.contentView addSubview:self.ssidField];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        self.isDisconnectTrigger = (indexPath.row == 1);
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)saveTrigger {
    NSString *finalSSID = [self.ssidField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (finalSSID.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name Required" message:@"Please enter a WiFi network name." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *prefix = self.isDisconnectTrigger ? @"wifi_disconnect_" : @"wifi_connect_";
    NSString *triggerKey = [prefix stringByAppendingString:finalSSID];
    
    
    RCConfigManager *config = [RCConfigManager sharedManager];
    
    // Create friendly name
    NSString *subTitle = self.isDisconnectTrigger ? @"Disconnected from" : @"Connected to";
    NSString *friendlyName = [NSString stringWithFormat:@"%@ %@", subTitle, finalSSID];
    
    if (self.triggerKey) {
        // Handle migration if key changed
        if (![self.triggerKey isEqualToString:triggerKey]) {
            NSDictionary *oldData = [config triggerDataForKey:self.triggerKey];
            NSArray *actions = oldData[@"actions"] ?: @[];
            
            NSDictionary *newData = @{
                @"name": friendlyName,
                @"enabled": @YES,
                @"actions": actions
            };
            [config updateTrigger:triggerKey withData:newData];
            [config removeTrigger:self.triggerKey];
        } else {
            // Just update metadata
            NSMutableDictionary *mutableData = [[config triggerDataForKey:triggerKey] mutableCopy];
            mutableData[@"name"] = friendlyName;
            [config updateTrigger:triggerKey withData:mutableData];
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // Create new
        NSDictionary *triggerData = @{
            @"name": friendlyName,
            @"enabled": @YES,
            @"actions": @[]
        };
        [config updateTrigger:triggerKey withData:triggerData];
        
        // Redirect to action picker for the new trigger
        RCActionsViewController *vc = [[RCActionsViewController alloc] initWithTriggerKey:triggerKey];
        NSMutableArray *vcs = [self.navigationController.viewControllers mutableCopy];
        [vcs removeLastObject]; // Remove self
        [vcs addObject:vc];
        [self.navigationController setViewControllers:vcs animated:YES];
    }
}

@end
