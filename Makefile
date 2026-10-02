# ====== Basic Settings ======
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = WhatsApp

include $(THEOS)/makefiles/common.mk

# ====== Project Settings ======
TWEAK_NAME = DevlandUltimate

DevlandUltimate_FILES = \
    Tweak.xm \
    DevRSettingsViewController.mm \
    DevLandSettings.m

DevlandUltimate_FRAMEWORKS = \
    UIKit \
    Contacts \
    CoreLocation \
    MapKit \
    WebKit

DevlandUltimate_PRIVATE_FRAMEWORKS = \
    Preferences \
    ContactsUI \
    ChatKit

DevlandUltimate_CFLAGS = \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -Wno-unsupported-availability-guard \
    -I.

include $(THEOS_MAKE_PATH)/tweak.mk

# ====== Post Install ======
after-install::
	install.exec "killall -9 WhatsApp || :"
