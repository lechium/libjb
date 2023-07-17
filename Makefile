TARGET := appletv:clang:latest:9.0
DEBUG=0
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libjb

libjb_FILES = libjb.m APFSHelper.m
libjb_CFLAGS = -fobjc-arc -Iinclude
libjb_LDFLAGS = -framework APFS -framework IOKit -L. -FFrameworks
libjb_INSTALL_PATH = /fs/jb/usr/lib

include $(THEOS_MAKE_PATH)/library.mk
