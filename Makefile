ifeq ($(DUO_IOS14_ROOTFUL),1)
# Taurine iOS 14.3: rootful uses iphoneos-arm and original /Library paths.
ARCHS = arm64
TARGET = iphone:clang:14.5:14.0
THEOS_PACKAGE_SCHEME =
else
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME ?= roothide
endif
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DuoBar
ifeq ($(DUO_IOS14_ROOTFUL),1)
DuoBar_FILES = Sources/Tweak14.xm Sources/DuoGlyphView.m
else
DuoBar_FILES = Sources/Tweak.xm Sources/DuoGlyphView.m
endif
DuoBar_CFLAGS = -fobjc-arc -Wall -Wextra
DuoBar_FRAMEWORKS = UIKit QuartzCore CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += duobarprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
