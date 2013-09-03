#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

@interface kWidgetsSortedListController : PSListController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) NSMutableArray *enabled;
@property (nonatomic, retain) NSMutableArray *disabled;
@property (nonatomic, retain) NSMutableDictionary *buddyLockSettings;
@property (nonatomic, retain) NSMutableDictionary *dict;
@property (nonatomic, retain) UITableView *tblView;
- (id)initForContentSize:(CGSize)contentSize;
- (id)navigationTitle;
- (id)title;
@end