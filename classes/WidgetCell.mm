#import "WidgetCell.h"

@implementation WidgetCell
- (void)layoutSubviews {
	[super layoutSubviews];
	float padding = 16;
	self.imageView.frame = CGRectMake(padding/2.0f, padding/2.0f, self.frame.size.width - padding, self.frame.size.height - padding);
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}
@end