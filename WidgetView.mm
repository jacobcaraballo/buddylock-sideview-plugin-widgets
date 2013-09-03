#import "WidgetView.h"

//Custom Imports
#import <AVFoundation/AVFoundation.h>
#import "classes/WidgetsSortedListController.h"
#import "substrate.h"
#import "classes/WidgetCell.h"

#import <Social/Social.h>

//Custom Classes
@interface NoteView : UITextView <UITextViewDelegate>
@end
@implementation NoteView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.font = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
    }
    return self;
}
- (void)drawRect:(CGRect)rect {
    //Get the current drawing context   
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    //Set the line color and width
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.816 alpha:1.000].CGColor);
    CGContextSetLineWidth(context, 1.0f);
    //Start a new Path
    CGContextBeginPath(context);

    //Find the number of lines in our textView + add a bit more height to draw lines in the empty part of the view
    NSUInteger numberOfLines = (self.contentSize.height + self.bounds.size.height) / self.font.leading;

    //Set the line offset from the baseline. (I'm sure there's a concrete way to calculate this.)
    CGFloat baselineOffset = 6.0f;

    //iterate over numberOfLines and draw each line
    for (int x = 0; x < numberOfLines; x++) {
        //0.5f offset lines up line with pixel boundary
        CGContextMoveToPoint(context, self.bounds.origin.x, self.font.leading*x + 0.5f + baselineOffset);
        CGContextAddLineToPoint(context, self.bounds.size.width, self.font.leading*x + 0.5f + baselineOffset);
    }

    //Close our Path and Stroke (draw) it
    CGContextClosePath(context);
    CGContextStrokePath(context);
}
- (void)dealloc {
	[super dealloc];
}
@end

//you can set custom properties/methods here, unless you need them public
@interface WidgetView() {
	float version;
}
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) UITableViewCell *selectedCell;
@property (nonatomic, retain) NSMutableArray *widgets;
@property (nonatomic, retain) UIView *brightnessView;
@property (nonatomic, retain) SLComposeViewController *tweetController;
@property (nonatomic, retain) SLComposeViewController *fbController;
@property (nonatomic, retain) UIViewController *viewControllerContainer;
@property (nonatomic, retain) UIView *viewControllerContainerView;
@end

@implementation WidgetView
@synthesize buddyLockSettings = _buddyLockSettings;

//custom
@synthesize tableView = _tableView;
@synthesize widgets = _widgets;
@synthesize selectedCell = _selectedCell;
@synthesize brightnessView = _brightnessView;
@synthesize tweetController = _tweetController;
@synthesize fbController = _fbController;
@synthesize viewControllerContainer = _viewControllerContainer;
@synthesize viewControllerContainerView = _viewControllerContainerView;

//you can access this instace through this class method. see external classes for example on how to use this method.
+ (id)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
     
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
     
    // executes a block object once and only once for the lifetime of an view
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
     
    // returns the same object each time
    return _sharedObject;
}

//don't change this
- (NSString *)buddyLockSettingsPath {
	return @"/var/mobile/Library/Preferences/com.ba.buddylock.plist";
}

- (id)init {
	if (self = [super init]) {
		[self setupListeners];
		
		//retrieve buddylock preferences
		self.buddyLockSettings = [[[NSMutableDictionary alloc] initWithContentsOfFile:[self buddyLockSettingsPath]] autorelease];
		
		//set the view ---- always use -mainFrame to set and retrieve the frame, basically leave this alone
		self.frame = [self mainFrame];
		//no need to add this view to any superview, i'll do that part :)
		
		//set background color
		//if you want the color to match the users theme, set -matchUserTheme below to YES
		self.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.90];
		
		//device firmware version -- if needed
		version = [[[UIDevice currentDevice] systemVersion] floatValue];
		
		//custom methods
		[self setupArray];
		[self setupWidgetsTable];
	}
	return self;
}

//if you use settings, return YES
//if this is returning YES, you need to implement the following two methods -settingsController and -settings, if not, your settings will not load
- (BOOL)shouldUseSettings {
	return YES;
}

//if you have settings for your sideview, return the controllers class here.
//this controller will show up in the side views section of the BuddyLock settings
//if you're side view doesn't require settings, simply return nil;
//if you choose to have settings, please return settings in -settings below
- (Class)settingsController {
	return [WidgetsSortedListController class];
}

//if you have settings, this is required
//if you don't have settings, simply return nil
- (id)settings {
	NSDictionary *settings = [self.buddyLockSettings objectForKey:[self identifier]]; //check if settings already exist
	
	//if you don't check if settings already exist, settings are not gonna update, as everytime the settings are returned it will return the primarily created settings
	
	if (!settings) { //if settings don't exist, create them
		NSArray *values = [NSArray arrayWithObjects:@"torch", @"brightness", @"note", @"fb", @"tweet", @"dnd", @"airplane", @"wifi", @"bluetooth", @"respring", nil];
		NSArray *names = [NSArray arrayWithObjects:@"Flashlight", @"Brightness", @"Notes", @"Facebook", @"Twitter", @"Do Not Disturb", @"Airplane Mode", @"Wifi", @"Bluetooth", @"Respring", nil];
		NSDictionary *displayNames = [NSDictionary dictionaryWithObjects:names forKeys:values];
		NSArray *enabled = [NSArray arrayWithArray:values];
		NSArray *disabled = [NSArray array];
	
		settings = [NSDictionary dictionaryWithObjectsAndKeys:
								  displayNames, @"names",
								  enabled, @"enabled",
								  disabled, @"disabled", nil];
	}
	
	//return an autoreleased instance
	//if you want to allocate and initialize your object, then remember to release/autorelease it when returning it, as I don't do this for you
	return settings;
	/*
	!!!!! IMPORTANT !!!!!
	these settings are placed in the BuddyLock Preferences (self.buddyLockSettings) with your identifier as the key:
		->	[self.buddyLockSettings setObject:[sideView settings] forKey:[sideView identifier]];
	
	so, when you need to retrieve or update your settings, always set in self.buddyLockSettings and make sure your key is your identifier. Then you can write to file.
		-> you can simply use the following method -updateSettings: which will set your object and write to file for you
	
	--- if you use a key other than your identifier to update settings, your views settings will never update. They will remain with the default settings returned here.
	*/
	
}

//this can be used to update your settings 
- (void)updateSettings:(id)settings {
	if (![self settings]) return;
	[self.buddyLockSettings setObject:settings forKey:[self identifier]];
	[self writeBuddyLockSettings];
}

//use if you need to write an updated buddyLockSettings dictionary
//you can also use the previous -updateSettings: method, which calls this method.
//this will do the obvious -- write the buddyLockSettings to the settings path
- (void)writeBuddyLockSettings {
	[self.buddyLockSettings writeToFile:[self buddyLockSettingsPath] atomically:YES];
}

#pragma mark - notifications
//register notifications to observe sideview events
- (void)setupListeners {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sideViewWillOpen:) name:@"sideViewWillOpen" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sideViewDidOpen:) name:@"sideViewDidOpen" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sideViewWillClose:) name:@"sideViewWillClose" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sideViewDidClose:) name:@"sideViewDidClose" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buddyLockTouchesBegan:) name:@"buddyLockTouchesBegan" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buddyLockTouchesEnded:) name:@"buddyLockTouchesEnded" object:nil];
}

//unregister notifications -- called in dealloc
- (void)removeListeners {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"sideViewWillOpen" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"sideViewDidOpen" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"sideViewWillClose" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"sideViewDidClose" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"buddyLockTouchesBegan" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"buddyLockTouchesEnded" object:nil];
}

//if you plan on removing any of the following observer methods, please remove it's respective listener from the -setupListeners & -removeListeners methods above,
//so that you're not sending a message to a nonexistent method
- (void)sideViewWillOpen:(NSNotification *)notification {
	UIView *sideView = [notification object];
	if (self != sideView) return; //make sure we're not messing around with another sideview
}
- (void)sideViewDidOpen:(NSNotification *)notification {
	UIView *sideView = [notification object];
	if (self != sideView) return;
}
- (void)sideViewWillClose:(NSNotification *)notification {
	UIView *sideView = [notification object];
	if (self != sideView) return;
}
- (void)sideViewDidClose:(NSNotification *)notification {
	UIView *sideView = [notification object];
	if (self != sideView) return;
	
	[self.tableView setContentOffset:CGPointZero animated:NO];
}
- (void)buddyLockTouchesBegan:(NSNotification *)notification {
	if (self.brightnessView) [self destroyBrightnessView];
}
- (void)buddyLockTouchesEnded:(NSNotification *)notification {
	//touches ended. do stuff..
}

#pragma mark - main methods
//this returns the window that holds your sideview
//just don't ever call this in init, as it has not been set yet and will return NULL
//an example for use would be having buttons that add an activity sheet to the window -- when the button is pressed, it calls a method set in here and the sheet is added to this window
//add any outside subviews to this window. see examples below where I add a noteview and the brightnessView to the window
- (UIWindow *)buddyLockWindow {
	//as simple as that :)
	return [self superview];
}

//this returns the view wherein buddyLock lives
//NEVER ADD SUBVIEWS TO THIS VIEW -- THEY WILL NOT WORK -- ADD THEM TO THE -buddyLockWindow ABOVE!
/*
	methods you can call:
		- (id)trackSlider; -- returns the track slider instance
		- (void)showTrack; -- call if you need to show the track slider
		- (void)hideTrack; -- call if you need to hide the track slider
		- (void)trackDisabled; -- resets the track slider and closes your sideView
		- (void)prepareForUnlock; -- if your view unlocks the lockscreen, please call this so that BuddyLock may prepare for the unlock
		- (void)prepareForRelock; -- if you need to relock the phone after calling -prepareForUnlock, use this so that we may put everything back in its place
		- (void)enableSleep:(BOOL)enabled -- send NO to disable screen dimming and sleep, send YES to enable it. if you disable sleep, remember to enable it again
		- (void)setDisableInteraction:(BOOL)disabled -- call if you don't want the user to mess with buddylock for some reason (e.g. popup view)
		- (void)disableResignResponder:(BOOL)disabled -- sometimes the keyboard will hide itself, because sbawayview will resign it. If you need to use the keyboard, disable the responder first. enable it again when done using the keyboard by sending NO.
		- (void)setShouldShowTrack:(BOOL)shouldShow -- call if you need to keep the track slider hidden. remember to set back to YES when done.

----- if you need extra methods for something else, email me at support@buddyapps.us -----

*/
- (UIView *)buddyLockView {
	return [[self buddyLockWindow] buddyLockView];
}

//set the frame of the view here (required)
- (CGRect)mainFrame {
	CGRect frame = [UIScreen mainScreen].bounds;
	
	//adjust for status bar (20px height)
	//if you don't adjust for the status bar height, the status bar will cover the top 20px of your view
	//only adjust if the status bar isn't hidden
	bool statusBarHidden = [[self.buddyLockSettings objectForKey:@"kHideStatusBar"] boolValue];
	if (!statusBarHidden) {
		frame.origin.y += 20;
		frame.size.height -= 20;
	}
	
	//now you can set your frame's position & dimensions
	frame.size.width = 60;
	
	//return the frame
	return frame;
}

//you can use this method if you want a padded view (optional)
- (CGRect)mainFrame:(CGRect)frame WithPadding:(float)padding {
	frame.size.height -= padding*2;
	frame.size.width -= padding*2;
	frame.origin.x += padding;
	frame.origin.y += padding;
	return frame;
}

//set here if you want your view's backgroundColor to match the users theme
//if user has no theme set, it will default to whatever background you set
- (BOOL)matchUserTheme {
	return YES;
}

//I need to know what your view's name is for settings -- if this isn't set, it won't be loaded into the settings
- (NSString *)name {
	return @"Widgets";
}

//set a weird identifier -- without this, your view will not be loaded -- make this unique to you and make sure no one else will use this or your view may not load
- (NSString *)identifier {
	return @"jacobjahzielcaraballo031989-com.ba.widgets-imsosupercool"; //i doubt anyone else will have this, so looks good
}

//do whatever you want beyond this point
//the following methods (besides -dealloc) are not required as they are specific to the side view
//you can read through the following to have an idea on how to use the buddyLockView methods
- (void)setupArray {
	self.widgets = [[NSMutableArray alloc] init];
	NSDictionary *widgetsDict = [self settings];
	NSArray *enabled = [widgetsDict objectForKey:@"enabled"];
	
	for (int i = 0; i < enabled.count; i++) {
		NSString *key = [enabled objectAtIndex:i];
		
		if ([key isEqualToString:@"fb"] || [key isEqualToString:@"tweet"] || [key isEqualToString:@"dnd"])
			if (version < 6.0) continue;
		
		[self.widgets addObject:key];
	}
}

- (void)setupWidgetsTable {
	CGRect frame = self.frame;
	frame.origin.y = 0;
	self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.userInteractionEnabled = YES;
	self.tableView.alwaysBounceVertical = YES;
	self.tableView.showsVerticalScrollIndicator = NO;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.canCancelContentTouches = YES;
	self.tableView.delaysContentTouches = NO;
	self.tableView.separatorColor = [UIColor colorWithWhite:1.0f alpha:0.4f];

	[self addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.widgets.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"theCell";
	WidgetCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (!cell) {
		cell = [[[WidgetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		cell.contentView.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.20];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	NSString *key = [self.widgets objectAtIndex:indexPath.row];
	
	cell.imageView.image = [UIImage imageNamed:[@"buddylock_widgets_" stringByAppendingString:key]];
	
	//cell.textLabel.text = key;
	return cell;
}
- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selectedCell) {
		self.selectedCell.contentView.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.20];
		self.selectedCell = nil;
	}
	
	self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	self.selectedCell.contentView.backgroundColor = [UIColor colorWithWhite:0.20 alpha:0.20];
}
- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selectedCell) self.selectedCell.contentView.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.20];
	self.selectedCell = nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self activateWidget:indexPath.row];
	[[self buddyLockView] trackDisabled];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.selectedCell) self.selectedCell.contentView.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.20];
	self.selectedCell = nil;
}

//semi-dirty hack to prevent empty cells from showing :)
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[[UIView alloc] init] autorelease];
	view.backgroundColor = [UIColor clearColor];
    return view;
}

- (void)noteDidCancel:(id)sender {
	[self dismissNoteView:NO];
}
- (void)noteDidSave:(id)sender {
	[self dismissNoteView:YES];
}
- (void)activatorTorchToggle {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	
	for (AVCaptureDevice *device in devices) {
		if ([device hasFlash]) {
			[device lockForConfiguration:nil];
			
			if (device.torchMode == AVCaptureTorchModeOff || device.torchMode == AVCaptureTorchModeOff) [device setTorchMode:AVCaptureTorchModeOn];
			else [device setTorchMode:AVCaptureTorchModeOff];
			
			[device unlockForConfiguration];
		}
	}
}
- (void)activatorBrightness {
	if (self.brightnessView) return;
	[[self buddyLockView] setShouldShowTrack:NO];
	[[self buddyLockView] setDisableInteraction:YES];
	
	if ([[[self buddyLockView] trackSlider] alpha] == 1) [[self buddyLockView] hideTrack];
	[[self buddyLockView] enableSleep:NO];
	
	float currentBrightness = 0.0f;
	if (version >= 6.0) currentBrightness = [UIScreen mainScreen].brightness;
	else currentBrightness = MSHookIvar<float>([UIApplication sharedApplication], "_currentBacklightLevel");

	self.brightnessView = [[UIView alloc] initWithFrame:CGRectMake(0, [self buddyLockWindow].frame.size.height, [self buddyLockWindow].frame.size.width, 50)];
	self.brightnessView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
	
	UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 15, self.brightnessView.frame.size.width - 20, 20)];
	slider.minimumValue = 0.0;
	slider.maximumValue = 1.0;
	slider.value = currentBrightness;
	slider.continuous = YES;
	
	[slider addTarget:self action:@selector(brightnessChanged:) forControlEvents:UIControlEventValueChanged];
	
	[self.brightnessView addSubview:slider];
	[[self buddyLockWindow] addSubview:self.brightnessView];
	
	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.brightnessView.frame = CGRectMake(0, [self buddyLockWindow].frame.size.height - 50, [self buddyLockWindow].frame.size.width, 50);
	} completion:NULL];
}
- (void)brightnessChanged:(UISlider *)slider {
	if (version >= 6.0) [[UIScreen mainScreen] setBrightness:slider.value];
	else [[objc_getClass("SBBrightnessController") sharedBrightnessController] _setBrightnessLevel:slider.value showHUD:FALSE];
}
- (void)destroyBrightnessView {
	[[self buddyLockView] enableSleep:YES];
	
	[UIView animateWithDuration:0.3 animations:^{
		self.brightnessView.frame = CGRectMake(0, [self buddyLockWindow].frame.size.height, [self buddyLockWindow].frame.size.width, 50);
	} completion:^(BOOL finished){
		[[self buddyLockView] setShouldShowTrack:YES];
		[[self buddyLockView] setDisableInteraction:NO];
		[[self buddyLockView] showTrack];
		
		for (UISlider *slider in [self.brightnessView subviews]) {
			[slider removeFromSuperview];
			[slider release];
		}
	
		[self.brightnessView removeFromSuperview];
		[self.brightnessView release];
		self.brightnessView = nil;
	}];
}
- (void)activatorRespring {
	system("killall SpringBoard");
}
- (void)presentNoteInView {
	[[self buddyLockView] setDisableInteraction:YES];
	[[self buddyLockView] enableSleep:NO];
	[[self buddyLockView] disableResignResponder:YES];
	
	//HOLDING VIEW
	UIView *superview = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	superview.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.400];
	superview.tag = 4000;
	
	//VIEW
	UIView *noteView = [[UIView alloc] initWithFrame:CGRectMake(5, -200, 310, 200)];
	noteView.backgroundColor = [UIColor colorWithWhite:0.916 alpha:1.000];
	noteView.tag = 4001;
	noteView.clipsToBounds = YES;
	
	[[noteView layer] setMasksToBounds:YES];
	[[noteView layer] setCornerRadius:6.0f];
	[[noteView layer] setShadowColor:[UIColor blackColor].CGColor];
	[[noteView layer] setShadowOpacity:1.0f];
	[[noteView layer] setShadowRadius:3.0f];
	[[noteView layer] setShadowOffset:CGSizeMake(2.0f, 2.0f)];
	
	//CREATE NAVIGATION BAR
	UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, noteView.frame.size.width, 44)];
	navBar.tintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.000];
	
	//CREATE ITEM FOR THE BAR
	UINavigationItem *navItem = [[UINavigationItem alloc] init];
	
	//TITLE LABEL
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.textColor = [UIColor colorWithWhite:0.240 alpha:0.850];
	titleLabel.shadowColor = [UIColor colorWithWhite:0.916 alpha:0.7];
	titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.text = @"Note";
	titleLabel.textAlignment = NSTextAlignmentCenter;
	
	[navItem setTitleView:titleLabel];
	[titleLabel sizeToFit];
	
	//CREATE AND ADD BUTTONS
	UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(noteDidCancel:)];
	UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(noteDidSave:)];
	
	[titleLabel release];
	titleLabel = nil;
	
	[cancel setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:0.240 alpha:0.850],  UITextAttributeTextColor, [UIColor colorWithWhite:0.916 alpha:0.7], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
	[save setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:0.240 alpha:0.850],  UITextAttributeTextColor, [UIColor colorWithWhite:0.916 alpha:0.7], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
	
	[navItem setLeftBarButtonItem:cancel];
	[navItem setRightBarButtonItem:save];
	
	[navBar setItems:[NSArray arrayWithObject:navItem]];
	
	[navItem release];
	navItem = nil;
	
	//TEXT VIEW
	NoteView *textView = [[[NoteView alloc] initWithFrame:CGRectMake(0, navBar.frame.size.height, noteView.frame.size.width, noteView.frame.size.height - navBar.frame.size.height)] autorelease];
	textView.tag = 4002;
	textView.delegate = self;	
	superview.alpha = 0;
	
	[noteView addSubview:textView];
	[noteView addSubview:navBar];
	[superview addSubview:noteView];
	[[self buddyLockWindow] addSubview:superview];
	
	[cancel release];
 	cancel = nil;
 	[save release];
 	save = nil;
	[navBar release];
	navBar = nil;
	
	[textView becomeFirstResponder];
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		superview.alpha = 1;
	} completion:^(BOOL finished) {
		[superview release];
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			noteView.frame = CGRectMake(noteView.frame.origin.x, 40, noteView.frame.size.width, noteView.frame.size.height);
		} completion:^(BOOL finished) {
			[noteView release];
		}];
	}];
}
- (void)dismissNoteView:(BOOL)shouldSave {
	UIView *superview = [[self buddyLockWindow] viewWithTag:4000];
	UIView *noteView = [superview viewWithTag:4001];
	UITextView *textView = (UITextView *)[noteView viewWithTag:4002];
	
	if (shouldSave) {
		NSString *string = [textView text];
		
		if (!string || [string isEqualToString:@""]) return;
		
		id noteContext = [[objc_getClass("NoteContext") alloc] init];
		[noteContext enableChangeLogging:YES];
		NSManagedObjectContext *context = [noteContext managedObjectContext];
		id store = [noteContext defaultStoreForNewNote];
		
		//create note
		id note = [NSClassFromString(@"NSEntityDescription") insertNewObjectForEntityForName:@"Note" inManagedObjectContext:context];
		id body = [NSClassFromString(@"NSEntityDescription") insertNewObjectForEntityForName:@"NoteBody" inManagedObjectContext:context];
		
		// set body parameters
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSString *firstLine = [lines objectAtIndex:0];
				
		NSString *content = @"";
		
		for (int i = 0; i < lines.count; i++) {
			NSString *current = [lines objectAtIndex:i];
			current = [current stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
			current = [current stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
			current = [current stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
			current = [current stringByReplacingOccurrencesOfString:@"\n" withString:@""];
			
			NSString *newCurrent = @"";
			BOOL shouldConvert = NO;
			
			for(int i = 0; i < current.length; i++) {
				char currentChar = [current characterAtIndex:i];				
				if (currentChar == ' ') {
					newCurrent = (shouldConvert) ? [newCurrent stringByAppendingString:@"&nbsp;"] : [newCurrent stringByAppendingFormat:@"%c", currentChar];
					shouldConvert = !shouldConvert;
				} else {
					shouldConvert = NO;
					newCurrent = [newCurrent stringByAppendingFormat:@"%c", currentChar];
				}
			}
						
			if ([newCurrent isEqualToString:@""]) newCurrent = @"<br>";
			if (i == 0) content = newCurrent;
			else content = [content stringByAppendingFormat:@"<div>%@</div>", newCurrent];
		}
		
		[body setContent:content];
		[body setOwner:note];
		[note setStore:store];
		[note setIntegerId:[noteContext nextIndex]];
		[note setTitle:firstLine];
		[note setSummary:firstLine];
		[note setBody:body];
		[note setCreationDate:[NSDate date]];
		[note setModificationDate:[NSDate date]];
		
		//save and release
		[noteContext saveOutsideApp:nil];
		[noteContext release];
	}
	
	[[self buddyLockView] disableResignResponder:NO];
	[textView resignFirstResponder];
	
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		noteView.frame = CGRectMake(noteView.frame.origin.x, -noteView.frame.size.height, noteView.frame.size.width, noteView.frame.size.height);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			superview.alpha = 0;
		} completion:^(BOOL finished) {
			[superview removeFromSuperview];
			[[self buddyLockView] enableSleep:YES];
			[[self buddyLockView] setDisableInteraction:NO];
		}];
	}];
}
- (void)activatorFacebook {
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
		self.viewControllerContainer = [[UIViewController alloc] init];
		self.viewControllerContainerView = [[UIView alloc] initWithFrame:[self buddyLockWindow].frame];
		[[self buddyLockWindow] addSubview:self.viewControllerContainerView];
		self.viewControllerContainer.view = self.viewControllerContainerView;
		
		self.fbController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
		
		[self.fbController setCompletionHandler:^(SLComposeViewControllerResult result) {
			[self.viewControllerContainerView removeFromSuperview];
			[self.viewControllerContainerView release];
			self.viewControllerContainerView = nil;

			[self.viewControllerContainer release];
			self.viewControllerContainer = nil;
			
			self.fbController = nil;

			[[self buddyLockView] enableSleep:YES];
			[[self buddyLockView] disableResignResponder:NO];
		}];
		
		[[self buddyLockView] enableSleep:NO];
		[[self buddyLockView] disableResignResponder:YES];
		[self.viewControllerContainer presentViewController:self.fbController animated:YES completion:nil];
	}
}
- (void)activatorTweet {
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
		self.viewControllerContainer = [[UIViewController alloc] init];
		self.viewControllerContainerView = [[UIView alloc] initWithFrame:[self buddyLockWindow].frame];
		[[self buddyLockWindow] addSubview:self.viewControllerContainerView];
		self.viewControllerContainer.view = self.viewControllerContainerView;
		
		self.tweetController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		
		self.tweetController.completionHandler = ^(SLComposeViewControllerResult result) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.viewControllerContainer dismissViewControllerAnimated:YES completion:^{
					[self.viewControllerContainerView removeFromSuperview];
					[self.viewControllerContainerView release];
					self.viewControllerContainerView = nil;

					[self.viewControllerContainer release];
					self.viewControllerContainer = nil;
					
					self.tweetController = nil;
					
					[[self buddyLockView] enableSleep:YES];
					[[self buddyLockView] disableResignResponder:NO];
				}];
			});
		};
		
		[[self buddyLockView] enableSleep:NO];
		[[self buddyLockView] disableResignResponder:YES];

		[self.viewControllerContainer presentViewController:self.tweetController animated:YES completion:nil];
	}
}
static BOOL isDNDEnabled;
- (void)activatorDoNotDisturb {
	id status = [objc_getClass("SBStatusBarDataManager") sharedDataManager];
	id dnd = [[objc_getClass("BBSettingsGateway") alloc] init];
	
	isDNDEnabled = !isDNDEnabled;
	[dnd setBehaviorOverrideStatus:!isDNDEnabled];
	
	[dnd release];
	dnd = nil;
	
	if (isDNDEnabled) {
		[status setStatusBarItem:1 enabled:NO];
		[status setStatusBarItem:1 enabled:YES];
	}
}
- (void)activatorAirplaneMode {
	id tm = [objc_getClass("SBTelephonyManager") sharedTelephonyManager];
	[tm setIsInAirplaneMode:![tm isInAirplaneMode]];
}
- (void)activatorWifi {
	id wifi = [objc_getClass("SBWiFiManager") sharedInstance];
	[wifi setWiFiEnabled:![wifi wiFiEnabled]];
}
- (void)activatorBluetooth {
	id blue = [objc_getClass("BluetoothManager") sharedInstance];
	[blue setEnabled:![blue enabled]];
}

//widget activation
- (void)activateWidget:(int)index {
	NSString *widget = [self.widgets objectAtIndex:index];
	
	if ([widget isEqualToString:@"torch"]) {
		for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
			if ([device hasFlash]) [self activatorTorchToggle];
	} else if ([widget isEqualToString:@"brightness"]) {
		[self activatorBrightness];
	} else if ([widget isEqualToString:@"note"]) {
		[self presentNoteInView];
	} else if ([widget isEqualToString:@"fb"]) {
		if (version >= 6.0) [self activatorFacebook];
	} else if ([widget isEqualToString:@"tweet"]) {
		if (version >= 6.0) [self activatorTweet];
	} else if ([widget isEqualToString:@"dnd"]) {
		if (version >= 6.0) [self activatorDoNotDisturb];
	} else if ([widget isEqualToString:@"airplane"]) {
		[self activatorAirplaneMode];
	} else if ([widget isEqualToString:@"wifi"]) {
		[self activatorWifi];
	} else if ([widget isEqualToString:@"bluetooth"]) {
		[self activatorBluetooth];
	} else if ([widget isEqualToString:@"respring"]) {
		[self activatorRespring];
	}
}

//cleanup
- (void)dealloc {
	[self removeListeners]; //stop sending notifications
	
	if (self.tableView) [self.tableView release];
	self.tableView = nil;
	if (self.widgets) [self.widgets release];
	self.widgets = nil;
	self.selectedCell = nil;
	
	[super dealloc];
}

@end