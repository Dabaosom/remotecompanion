FINALPACKAGE=1
THEOS_PACKAGE_COMPRESSION = gzip
THEOS ?= /opt/theos
THEOS_DEVICE_IP = iphone.local
INSTALL_TARGET_USER = mobile
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ARCHS = arm64 arm64e
else
ARCHS = arm64
endif
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RemoteCommand
TOOL_NAME = rc-root

# Lua source files
LUA_FILES = $(wildcard lua/*.c)

RemoteCommand_FILES = Tweak.x RCNFCManager.x $(LUA_FILES)
RemoteCommand_CFLAGS = -fobjc-arc -Ilua -DLUA_USE_IOS
RemoteCommand_FRAMEWORKS = UIKit CoreNFC IOKit
RemoteCommand_PRIVATE_FRAMEWORKS = AppSupport MediaRemote MobileCoreServices FrontBoardServices BackBoardServices MediaPlayer DoNotDisturb BiometricKit AccessibilityUtilities
RemoteCommand_LDFLAGS += -F/opt/theos/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks

rc-root_FILES = rc-root.c
rc-root_INSTALL_PATH = /usr/bin
rc-root_CODESIGN_FLAGS = -Sentitlements.plist
rc-root_FRAMEWORKS = CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk
