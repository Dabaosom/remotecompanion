#import "RCScheduledTriggerViewController.h"
#import "RCConfigManager.h"
#import "RCActionsViewController.h"

@interface RCScheduledTriggerViewController ()
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSMutableArray *selectedDays; // 1=Sun, 2=Mon, etc.
@property (nonatomic, strong) NSArray *dayNames;
@property (nonatomic, strong) NSString *triggerKey;
@end

@implementation RCScheduledTriggerViewController

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
    self.title = self.triggerKey ? @"Edit Schedule" : @"New Schedule";
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(applyTweaks) 
                                                  name:@"RCConfigTweaksChangedNotification" 
                                                object:nil];
    
    [self applyTweaks];
    
    self.dayNames = @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];
    
    if (self.triggerKey) {
        NSDictionary *data = [[RCConfigManager sharedManager] triggerDataForKey:self.triggerKey];
        NSDictionary *sched = data[@"schedule"];
        if (sched) {
            NSInteger hour = [sched[@"hour"] integerValue];
            NSInteger minute = [sched[@"minute"] integerValue];
            NSArray *days = sched[@"days"];
            
            NSDateComponents *comp = [[NSDateComponents alloc] init];
            comp.hour = hour;
            comp.minute = minute;
            NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comp];
            
            if (!self.timePicker) {
                self.timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 150)];
                self.timePicker.datePickerMode = UIDatePickerModeTime;
                if (@available(iOS 13.4, *)) {
                    self.timePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
                }
            }
            [self.timePicker setDate:date animated:NO];
            self.selectedDays = [NSMutableArray arrayWithArray:days];
        } else {
            self.selectedDays = [NSMutableArray arrayWithArray:@[@1, @2, @3, @4, @5, @6, @7]];
        }
    } else {
        self.selectedDays = [NSMutableArray arrayWithArray:@[@1, @2, @3, @4, @5, @6, @7]]; // Default to all days
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

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1; // Time Picker
    return 7; // Days of the week
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Execution Time";
    return @"Repeat Days";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (!self.timePicker) {
            self.timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 150)];
            self.timePicker.datePickerMode = UIDatePickerModeTime;
            if (@available(iOS 13.4, *)) {
                self.timePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
            }
        }
        
        self.timePicker.center = CGPointMake(tableView.bounds.size.width / 2, 80);
        [cell.contentView addSubview:self.timePicker];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DayCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DayCell"];
        }
        
        cell.textLabel.text = self.dayNames[indexPath.row];
        NSNumber *dayNum = @(indexPath.row + 1);
        if ([self.selectedDays containsObject:dayNum]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 160;
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        NSNumber *dayNum = @(indexPath.row + 1);
        if ([self.selectedDays containsObject:dayNum]) {
            [self.selectedDays removeObject:dayNum];
        } else {
            [self.selectedDays addObject:dayNum];
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)saveTrigger {
    if (self.selectedDays.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Day Required" message:@"Please select at least one day." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self.timePicker.date];
    NSInteger hour = components.hour;
    NSInteger minute = components.minute;
    
    // Create friendly name - e.g. "16:00 (Mon, Tue)"
    NSString *timeStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)hour, (long)minute];
    
    NSMutableArray *shortDays = [NSMutableArray array];
    NSArray *dayShortNames = @[@"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat"];
    
    // Sort selected days for consistent display
    [self.selectedDays sortUsingSelector:@selector(compare:)];
    
    for (NSNumber *dayNum in self.selectedDays) {
        [shortDays addObject:dayShortNames[[dayNum integerValue] - 1]];
    }
    
    NSString *daysStr = (shortDays.count == 7) ? @"Daily" : [shortDays componentsJoinedByString:@", "];
    NSString *friendlyName = [NSString stringWithFormat:@"%@ (%@)", timeStr, daysStr];

    RCConfigManager *config = [RCConfigManager sharedManager];
    NSString *triggerKey = self.triggerKey;
    
    if (triggerKey) {
        // Update existing configuration
        NSMutableDictionary *mutableData = [[config triggerDataForKey:triggerKey] mutableCopy];
        mutableData[@"name"] = friendlyName;
        mutableData[@"schedule"] = @{
            @"hour": @(hour),
            @"minute": @(minute),
            @"days": self.selectedDays
        };
        [config updateTrigger:triggerKey withData:mutableData];
        
        // Return to previous view
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // Generate a new unique key
        triggerKey = [NSString stringWithFormat:@"sched_%ld_%ld_%ld", (long)hour, (long)minute, (long)[[NSDate date] timeIntervalSince1970]];
        
        NSDictionary *triggerData = @{
            @"name": friendlyName,
            @"enabled": @YES,
            @"actions": @[],
            @"schedule": @{
                @"hour": @(hour),
                @"minute": @(minute),
                @"days": self.selectedDays
            }
        };
        [config updateTrigger:triggerKey withData:triggerData];
        
        // Redirect to actions view
        RCActionsViewController *vc = [[RCActionsViewController alloc] initWithTriggerKey:triggerKey];
        NSMutableArray *vcs = [self.navigationController.viewControllers mutableCopy];
        [vcs removeLastObject]; // Remove self
        [vcs addObject:vc];
        [self.navigationController setViewControllers:vcs animated:YES];
    }
}

@end
