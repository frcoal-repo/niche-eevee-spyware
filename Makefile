TARGET := iphone:clang:15.0:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME=rootless
export SYSROOT = $(THEOS)/sdks/iPhoneOS15.0.sdk
export COPYFILE_DISABLE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = notification-test

notification-test_FILES = Tweak.x
notification-test_CFLAGS = -fobjc-arc 
notification-test_PRIVATE_FRAMEWORK = BulletinBoard
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = SylveonsNicheTokenLoggerSpywarePrefs

SylveonsNicheTokenLoggerSpywarePrefs_FILES = FRCOALNTWRootListController.m
SylveonsNicheTokenLoggerSpywarePrefs_FRAMEWORKS = UIKit
SylveonsNicheTokenLoggerSpywarePrefs_PRIVATE_FRAMEWORKS = Preferences
SylveonsNicheTokenLoggerSpywarePrefs_INSTALL_PATH = /Library/PreferenceBundles
SylveonsNicheTokenLoggerSpywarePrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

