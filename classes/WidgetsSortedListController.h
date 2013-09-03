#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

//you should always subclass PSListController if you're using settings
//this will be placed in the sideviews section of BL settings under "side view settings"
@interface WidgetsSortedListController : PSListController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) NSMutableArray *enabled;
@property (nonatomic, retain) NSMutableArray *disabled;
@property (nonatomic, retain) NSMutableDictionary *settings;
@property (nonatomic, retain) UITableView *tableView;

//if you are familiar with PSListController class, you can also implement the -(id)specifiers method
//I won't go into depth on that, you can go to google university for that... (google.com)

- (id)initForContentSize:(CGSize)contentSize;
- (id)navigationTitle;
- (id)title;
@end