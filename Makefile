ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME ?= roothide
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DuoBar
DuoBar_FILES = Sources/Tweak.xm Sources/DuoGlyphView.m
DuoBar_CFLAGS = -fobjc-arc -Wall -Wextra -DDUO_IOS26_EXPERIMENTAL=1
DuoBar_FRAMEWORKS = UIKit QuartzCore CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += duobarprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
