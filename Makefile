GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

# you should be familiar on how to create a bundle if you are planning on creating a BuddyLock SideView
# remember to update the Info.plist in /Resources according to the bundle name and class

BUNDLE_NAME = widgets
widgets_FILES = WidgetView.mm classes/WidgetsSortedListController.mm classes/WidgetCell.mm
widgets_INSTALL_PATH = /Library/BuddyLock/SideViews
widgets_FRAMEWORKS = UIKit Foundation CoreGraphics AVFoundation Social
widgets_PRIVATE_FRAMEWORKS = Preferences Notes

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/BuddyLock/SideViews$(ECHO_END)
