#import "RCUITweaker.h"
#import "RCConfigManager.h"

static NSString *const RCTweaksChangedNotification = @"RCConfigTweaksChangedNotification";
static CGFloat const RCHeaderHeight = 44.0f;
static CGFloat const RCPanelInset = 12.0f;

@interface RCUITweakSlider : UISlider
@property (nonatomic, copy) NSString *tweakKey;
@property (nonatomic, weak) UILabel *valueLabel;
@end

@implementation RCUITweakSlider
@end

@interface RCUITweakerSliderRowView : UIView
@property (nonatomic, strong, readonly) RCUITweakSlider *slider;
- (instancetype)initWithTitle:(NSString *)title
                          key:(NSString *)key
                 currentValue:(CGFloat)currentValue;
@end

@implementation RCUITweakerSliderRowView

- (instancetype)initWithTitle:(NSString *)title
                          key:(NSString *)key
                 currentValue:(CGFloat)currentValue {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.text = title;
        nameLabel.textColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
        nameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [self addSubview:nameLabel];
        
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.textColor = [UIColor whiteColor];
        valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
        valueLabel.textAlignment = NSTextAlignmentRight;
        valueLabel.text = [NSString stringWithFormat:@"%.2f", currentValue];
        [self addSubview:valueLabel];
        
        _slider = [[RCUITweakSlider alloc] initWithFrame:CGRectZero];
        _slider.translatesAutoresizingMaskIntoConstraints = NO;
        _slider.minimumValue = 0.0f;
        _slider.maximumValue = 1.0f;
        _slider.value = currentValue;
        _slider.tweakKey = key;
        _slider.valueLabel = valueLabel;
        [self addSubview:_slider];
        
        [NSLayoutConstraint activateConstraints:@[
            [nameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [nameLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:valueLabel.leadingAnchor constant:-8.0],
            
            [valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [valueLabel.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
            [valueLabel.widthAnchor constraintEqualToConstant:52.0],
            
            [_slider.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_slider.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_slider.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:6.0],
            [_slider.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    return self;
}

@end

@interface RCUITweakerView : UIView
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *minimizeButton;
@property (nonatomic, strong) UIButton *btnCopySettings;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;

@property (nonatomic, assign) BOOL isMinimized;
@property (nonatomic, assign) CGRect expandedFrame;
@end

@implementation RCUITweakerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.96];
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor colorWithRed:0.30 green:0.30 blue:0.30 alpha:1.0].CGColor;
        self.layer.borderWidth = 1.0;
        
        [self setupHeader];
        [self setupScrollView];
        [self buildSliders];
        
        // Drag gesture
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.headerView addGestureRecognizer:pan];
        
        self.expandedFrame = frame;
    }
    return self;
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.backgroundColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    [self addSubview:self.headerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.headerView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:RCHeaderHeight]
    ]];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"UI Tweaker";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.headerView addSubview:self.titleLabel];
    
    self.minimizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.minimizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.minimizeButton setImage:[UIImage systemImageNamed:@"minus"] forState:UIControlStateNormal];
    self.minimizeButton.tintColor = [UIColor whiteColor];
    [self.minimizeButton addTarget:self action:@selector(toggleMinimize) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.minimizeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:14.0],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        
        [self.minimizeButton.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-6.0],
        [self.minimizeButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.minimizeButton.widthAnchor constraintEqualToConstant:32.0],
        [self.minimizeButton.heightAnchor constraintEqualToConstant:32.0]
    ]];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    self.contentStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 14.0;
    [self.scrollView addSubview:self.contentStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:RCPanelInset],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-RCPanelInset],
        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:10.0],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-RCPanelInset],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-(RCPanelInset * 2.0)]
    ]];
}

- (NSArray<NSDictionary *> *)tweakDefinitions {
    return @[
        @{@"key": @"mainBackground", @"name": @"Main BG", @"default": @(0.09)},
        @{@"key": @"settingsBackground", @"name": @"Settings BG", @"default": @(0.09)},
        @{@"key": @"actionPickerBackground", @"name": @"Select Actions BG", @"default": @(0.09)},
        @{@"key": @"blockBackground", @"name": @"Block BG", @"default": @(0.12)},
        @{@"key": @"separators", @"name": @"Separators", @"default": @(0.30)},
        @{@"key": @"borders", @"name": @"Borders", @"default": @(0.14)},
        @{@"key": @"navBar", @"name": @"Nav Bar BG", @"default": @(0.09)},
        @{@"key": @"selectionHighlight", @"name": @"Selection Highlight", @"default": @(0.15)}
        // Shadow controls are intentionally hidden for now. Keep keys in config/runtime for easy re-enable.
    ];
}

- (void)buildSliders {
    for (UIView *view in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    for (NSDictionary *info in [self tweakDefinitions]) {
        NSString *key = info[@"key"];
        NSString *name = info[@"name"];
        CGFloat def = [info[@"default"] floatValue];
        
        CGFloat currentVal = [[RCConfigManager sharedManager] tweakValueForKey:key defaultVal:def];
        
        RCUITweakerSliderRowView *row = [[RCUITweakerSliderRowView alloc] initWithTitle:name
                                                                                      key:key
                                                                             currentValue:currentVal];
        [row.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentStack addArrangedSubview:row];
    }
    
    // Add Copy button
    self.btnCopySettings = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnCopySettings.translatesAutoresizingMaskIntoConstraints = NO;
    [self.btnCopySettings setTitle:@"Copy Settings" forState:UIControlStateNormal];
    [self.btnCopySettings setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnCopySettings.backgroundColor = [UIColor systemBlueColor];
    self.btnCopySettings.layer.cornerRadius = 8;
    self.btnCopySettings.contentEdgeInsets = UIEdgeInsetsMake(8, 12, 8, 12);
    [self.btnCopySettings addTarget:self action:@selector(copySettings) forControlEvents:UIControlEventTouchUpInside];
    [self.contentStack addArrangedSubview:self.btnCopySettings];
    [self.btnCopySettings.heightAnchor constraintEqualToConstant:36.0].active = YES;
}

- (void)sliderChanged:(RCUITweakSlider *)slider {
    NSString *key = slider.tweakKey;
    if (key.length == 0) {
        return;
    }
    
    CGFloat val = slider.value;
    slider.valueLabel.text = [NSString stringWithFormat:@"%.2f", val];
    
    NSDictionary *currentTweaks = [[RCConfigManager sharedManager] colorTweaks];
    NSMutableDictionary *mutTweaks = currentTweaks ? [currentTweaks mutableCopy] : [NSMutableDictionary dictionary];
    mutTweaks[key] = @(val);
    
    [[RCConfigManager sharedManager] setColorTweaks:mutTweaks];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTweaksChangedNotification object:nil];
}

- (void)copySettings {
    NSDictionary *tweaks = [[RCConfigManager sharedManager] colorTweaks];
    NSMutableString *str = [NSMutableString stringWithString:@"Current UI Color Tweaks:\n"];
    
    for (NSDictionary *info in [self tweakDefinitions]) {
        NSString *key = info[@"key"];
        NSString *name = info[@"name"];
        CGFloat def = [info[@"default"] floatValue];
        CGFloat val = [tweaks[key] floatValue];
        if (tweaks[key] == nil) {
            val = def;
        }
        [str appendFormat:@"- %@ (%@): %.2f\n", name, key, val];
    }
    
    [UIPasteboard generalPasteboard].string = str;
    
    [self.btnCopySettings setTitle:@"Copied!" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.btnCopySettings setTitle:@"Copy Settings" forState:UIControlStateNormal];
    });
}



- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (!self.superview) {
        return;
    }
    
    CGPoint translation = [pan translationInView:self.superview];
    CGRect newFrame = self.frame;
    newFrame.origin.x += translation.x;
    newFrame.origin.y += translation.y;
    [pan setTranslation:CGPointZero inView:self.superview];
    
    UIEdgeInsets safeInsets = self.superview.safeAreaInsets;
    CGFloat minX = 8.0;
    CGFloat maxX = self.superview.bounds.size.width - newFrame.size.width - 8.0;
    CGFloat minY = safeInsets.top + 8.0;
    CGFloat maxY = self.superview.bounds.size.height - newFrame.size.height - 8.0;
    
    if (maxX < minX) maxX = minX;
    if (maxY < minY) maxY = minY;
    
    newFrame.origin.x = MIN(MAX(newFrame.origin.x, minX), maxX);
    newFrame.origin.y = MIN(MAX(newFrame.origin.y, minY), maxY);
    self.frame = newFrame;
    
    if (self.isMinimized) {
        CGRect expanded = self.expandedFrame;
        expanded.origin = newFrame.origin;
        self.expandedFrame = expanded;
    } else {
        self.expandedFrame = newFrame;
    }
}

- (void)toggleMinimize {
    self.isMinimized = !self.isMinimized;
    
    [UIView animateWithDuration:0.25 animations:^{
        if (self.isMinimized) {
            self.expandedFrame = self.frame;
            CGRect newFrame = self.frame;
            newFrame.size.height = RCHeaderHeight;
            self.frame = newFrame;
            self.scrollView.alpha = 0;
            [self.minimizeButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        } else {
            CGRect expanded = self.expandedFrame;
            if (expanded.size.height <= RCHeaderHeight) {
                expanded.size.height = 400.0;
            }
            self.frame = expanded;
            self.scrollView.alpha = 1;
            [self.minimizeButton setImage:[UIImage systemImageNamed:@"minus"] forState:UIControlStateNormal];
        }
    }];
}

@end

static RCUITweakerView *sharedTweakerView = nil;

@implementation RCUITweaker

+ (UIWindow *)activeWindow {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *candidate in windowScene.windows) {
                if (candidate.isKeyWindow) {
                    window = candidate;
                    break;
                }
            }
            if (!window && windowScene.windows.count > 0) {
                window = windowScene.windows.firstObject;
            }
            if (window) {
                break;
            }
        }
    }
    
    if (!window) {
        for (UIWindow *candidate in [UIApplication sharedApplication].windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
    }
    return window;
}

+ (void)show {
    if (sharedTweakerView) {
        [sharedTweakerView removeFromSuperview];
        sharedTweakerView = nil;
    }
    
    UIWindow *window = [self activeWindow];
    if (!window) return;
    
    UIEdgeInsets safeInsets = window.safeAreaInsets;
    CGFloat width = MIN(320.0, window.bounds.size.width - 24.0);
    if (width < 260.0) {
        width = window.bounds.size.width - 12.0;
    }
    
    CGFloat maxHeight = window.bounds.size.height - safeInsets.top - safeInsets.bottom - 24.0;
    CGFloat height = MIN(430.0, maxHeight);
    CGFloat x = MAX(6.0, window.bounds.size.width - width - 12.0);
    CGFloat y = safeInsets.top + 48.0;
    if (y + height > window.bounds.size.height - safeInsets.bottom - 8.0) {
        y = MAX(safeInsets.top + 8.0, window.bounds.size.height - safeInsets.bottom - height - 8.0);
    }
    
    sharedTweakerView = [[RCUITweakerView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    sharedTweakerView.expandedFrame = sharedTweakerView.frame;
    [window addSubview:sharedTweakerView];
}

+ (void)hide {
    if (sharedTweakerView) {
        [sharedTweakerView removeFromSuperview];
        sharedTweakerView = nil;
    }
}

@end
