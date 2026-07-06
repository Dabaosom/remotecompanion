ARCHS = arm64
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = rc-root
rc-root_FILES = rc-root.c
rc-root_INSTALL_PATH = /usr/bin
rc-root_CODESIGN_FLAGS = -Sentitlements.plist
rc-root_FRAMEWORKS = CoreFoundation

include $(THEOS_MAKE_PATH)/tool.mk
