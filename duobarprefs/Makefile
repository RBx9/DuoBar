ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME ?= roothide

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DuoBarPrefs
DuoBarPrefs_FILES = DuoRootListController.m
DuoBarPrefs_FRAMEWORKS = UIKit CoreFoundation
DuoBarPrefs_PRIVATE_FRAMEWORKS = Preferences
DuoBarPrefs_INSTALL_PATH = /Library/PreferenceBundles
DuoBarPrefs_CFLAGS = -fobjc-arc -Wall -Wextra

include $(THEOS_MAKE_PATH)/bundle.mk
