#import "WidgetsSortedListController.h"
#import "../WidgetView.h"

@implementation WidgetsSortedListController
@synthesize enabled = _enabled;
@synthesize disabled = _disabled;
@synthesize settings = _settings;
@synthesize tableView = _tableView;
- (id)initForContentSize:(CGSize)contentSize {
	if ((self = [super init])) {
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 44)];
		[self setView:view];
		[self setupArrays];
		[self setupTableView];
	}
	
	return self;
}
- (id)navigationTitle {
	return @"Widgets";
}
- (id)title {
	return @"Widgets";
}
- (NSString *)nameForValue:(NSString *)value {
	NSDictionary *names = [self.settings objectForKey:@"names"];
	return [names objectForKey:value];
}
- (void)savePreferences {
	[self.settings setObject:(NSArray *)self.enabled forKey:@"enabled"];
	[self.settings setObject:(NSArray *)self.disabled forKey:@"disabled"];
	[[WidgetView sharedInstance] updateSettings:(NSDictionary *)self.settings];
}
- (void)setupArrays {
	self.settings = [[[WidgetView sharedInstance] settings] mutableCopy];
	self.enabled = [[self.settings objectForKey:@"enabled"] mutableCopy];
	self.disabled = [[self.settings objectForKey:@"disabled"] mutableCopy];
}
- (void)setupTableView {
	self.tableView = [[UITableView alloc] initWithFrame:[[self view] frame] style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.editing = YES;
	[self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = 0;	
	if (section == 0) {
		rows = self.enabled.count;
	} else if (section == 1) {
		rows = self.disabled.count;
	}
	
	return rows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {	
	static NSString *cellIdentifier = @"theCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	
	NSString *title = @"";
	
	if (indexPath.section == 0) {
		title = [self nameForValue:[self.enabled objectAtIndex:indexPath.row]];
	} else if (indexPath.section == 1) {
		title = [self nameForValue:[self.disabled objectAtIndex:indexPath.row]];
	}
	
	cell.textLabel.text = title;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = @"";
	switch (section) {
		case 0:
			title = @"Enabled";
			break;
		case 1:
			title = @"Disabled";
			break;
		default:
			break;
	}
	
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *footerText = nil;
	
    if (section == 0) {
		footerText = @" ";
	} else {
		footerText = @"Facebook, Twitter, & Do Not Disturb will not work on firmwares prior to iOS 6.";
	}
    
    return footerText;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSMutableArray *source = (sourceIndexPath.section == 0) ? self.enabled : self.disabled;
	NSMutableArray *destination = (destinationIndexPath.section == 0) ? self.enabled : self.disabled;
	
	NSString *title = [source objectAtIndex:sourceIndexPath.row];
	[source removeObjectAtIndex:sourceIndexPath.row];
	[destination insertObject:title atIndex:destinationIndexPath.row];
	[self savePreferences];
}

- (void)dealloc {
	if (self.tableView) {
		[self.tableView release];
		self.tableView = nil;
	}
	
	if (self.enabled) {
		[self.enabled release];
		self.enabled = nil;
	}
	
	if (self.disabled) {
		[self.disabled release];
		self.disabled = nil;
	}
	
	if (self.settings) {
		[self.settings release];
		self.settings = nil;
	}
	
	[super dealloc];
}
@end