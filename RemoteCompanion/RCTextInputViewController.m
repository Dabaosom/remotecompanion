#import "RCTextInputViewController.h"

@interface RCTextInputViewController () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UISwitch *rootSwitch;
@end

@implementation RCTextInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = _promptTitle ?: @"Editor";
    
    // Add cancel and save buttons
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
        target:self 
        action:@selector(cancel)];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] 
        initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
        target:self 
        action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Create text view
    _textView = [[UITextView alloc] init];
    _textView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _textView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0]; // Slightly darkened again
    _textView.textColor = [UIColor whiteColor]; // White text
    _textView.layer.cornerRadius = 10;
    _textView.layer.masksToBounds = YES;
    _textView.textContainerInset = UIEdgeInsetsMake(15, 15, 15, 15);
    _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textView.autocorrectionType = UITextAutocorrectionTypeNo;
    _textView.keyboardType = UIKeyboardTypeDefault;
    _textView.editable = YES;
    _textView.selectable = YES;
    _textView.delegate = self;
    _textView.alwaysBounceVertical = YES;
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_textView];
    
    // Simple toolbar with just Done
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_textView action:@selector(resignFirstResponder)];
    [toolbar setItems:@[flexSpace, doneButton]];
    _textView.inputAccessoryView = toolbar;
    
    if (_initialText) {
        _textView.text = _initialText;
    }
    
    if (self.showRootToggle) {
        // Create container for toggle
        UIView *toggleContainer = [[UIView alloc] init];
        toggleContainer.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        toggleContainer.layer.cornerRadius = 10;
        toggleContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:toggleContainer];
        
        UILabel *rootLabel = [[UILabel alloc] init];
        rootLabel.text = @"Execute as Root";
        rootLabel.font = [UIFont systemFontOfSize:17];
        rootLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [toggleContainer addSubview:rootLabel];
        
        self.rootSwitch = [[UISwitch alloc] init];
        self.rootSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [self.rootSwitch addTarget:self action:@selector(rootSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        self.rootSwitch.on = self.isRootToggled;
        [toggleContainer addSubview:self.rootSwitch];
        
        [NSLayoutConstraint activateConstraints:@[
            [toggleContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
            [toggleContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
            [toggleContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15],
            [toggleContainer.heightAnchor constraintEqualToConstant:50],
            
            [rootLabel.leadingAnchor constraintEqualToAnchor:toggleContainer.leadingAnchor constant:15],
            [rootLabel.centerYAnchor constraintEqualToAnchor:toggleContainer.centerYAnchor],
            
            [self.rootSwitch.trailingAnchor constraintEqualToAnchor:toggleContainer.trailingAnchor constant:-15],
            [self.rootSwitch.centerYAnchor constraintEqualToAnchor:toggleContainer.centerYAnchor],
            
            [_textView.topAnchor constraintEqualToAnchor:toggleContainer.bottomAnchor constant:20],
            [_textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
            [_textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15],
            [_textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [_textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
            [_textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
            [_textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15],
            [_textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
        ]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_textView becomeFirstResponder];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rootSwitchChanged:(UISwitch *)sender {
    self.isRootToggled = sender.isOn;
}

- (void)save {
    NSString *text = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (_showRootToggle) {
        self.isRootToggled = self.rootSwitch.isOn;
    }
    
    if (_onComplete) {
        _onComplete(text);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
