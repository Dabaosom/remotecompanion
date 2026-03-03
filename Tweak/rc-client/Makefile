TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = rc-client

rc-client_FILES = rc-client.c
rc-client_CODESIGN_FLAGS = -Sentitlements.plist
rc-client_INSTALL_PATH = /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
