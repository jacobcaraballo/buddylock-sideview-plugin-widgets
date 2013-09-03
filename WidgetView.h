#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

//this is where your sideview lives
//the view will be pulled by BuddyLock and placed onto the lockscreen as a sideview
//I treat all sideviews as UIView's, so always subclass UIView!
@interface WidgetView : UIView <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate> //set whatever delegates you need (optional)
@property (nonatomic, retain) NSMutableDictionary *buddyLockSettings;
+ (id)sharedInstance;
- (id)init;
- (NSString *)identifier;
- (NSString *)name;
- (BOOL)matchUserTheme;
- (CGRect)mainFrame;
- (CGRect)mainFrame:(CGRect)frame WithPadding:(float)padding;
- (UIView *)buddyLockWindow;
- (BOOL)shouldUseSettings;
- (id)settingsController;
- (id)settings;
@end