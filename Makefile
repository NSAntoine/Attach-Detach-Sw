TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = attachdetachsw

attachdetachsw_FILES = $(wildcard Sources/attachdetachsw/*.swift)
attachdetachsw_PRIVATE_FRAMEWORKS = DiskImages2
attachdetachsw_SWIFTFLAGS = -ISources/attachdetachsw/ -suppress-warnings
attachdetachsw_CODESIGN_FLAGS = -Sentitlements.plist
attachdetachsw_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
