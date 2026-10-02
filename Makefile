# ====== Basic Settings ======
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = WhatsApp
DEPLOYMENT_IOS = 13.0

include $(THEOS)/makefiles/common.mk

# ====== Project Settings ======
TWEAK_NAME = DevlandUltimate

DevlandUltimate_FILES = \
    Tweak.xm \
    DevRSettingsViewController.mm \
    DevLandSettings.m \

DevlandUltimate_FRAMEWORKS = \
    UIKit \
    Contacts \
    CoreLocation \
    MapKit \
    WebKit \
    Preferences

DevlandUltimate_PRIVATE_FRAMEWORKS = \
    ContactsUI \
    ChatKit

DevlandUltimate_CFLAGS = \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -Wno-unsupported-availability-guard

DevlandUltimate_EXTRA_FRAMEWORKS = \
    Cephei \
    CepheiPrefs

include $(THEOS_MAKE_PATH)/tweak.mk

# ====== Subprojects ======
SUBPROJECTS += devlandprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# ====== Post Install ======
after-install::
	install.exec "killall -9 WhatsApp || :"
