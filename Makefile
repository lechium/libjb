
# PREFIX is environment variable, but if it is not set, then set default value
ifeq ($(PREFIX),)
    PREFIX := /usr
endif

SRC             := src
BUILD           := build
IOS_SDK         := iphoneos
IOS_SDK_PATH    := $(shell /usr/bin/xcrun --sdk $(IOS_SDK) --show-sdk-path)
TVOS_SDK        := appletvos
TVOS_SDK_PATH   := $(shell /usr/bin/xcrun --sdk $(TVOS_SDK) --show-sdk-path)
TARGET          := libjb
FILES           := $(wildcard *.mm) $(wildcard *.m)
PWD             := $(shell pwd)
IOS_CC          ?= xcrun -sdk iphoneos clang
INCLUDES        := -I. -Iinclude
LD_FLAGS_ALL    := $(INCLUDES) -lsystem -fmodules -Xclang -F. -L. -framework Foundation -framework APFS -framework IOKit -L. -fobjc-arc -dynamiclib -install_name $(PREFIX)/lib/$(TARGET).dylib
C_FLAGS_IOS     := -arch arm64 -arch arm64e -isysroot "$(IOS_SDK_PATH)" -Funi -miphoneos-version-min=8.1 -O
C_FLAGS_TVOS    := -arch arm64 -isysroot "$(TVOS_SDK_PATH)" -Funi -mappletvos-version-min=9.0 -O3
VERSION			:= $(shell cat version)
ROOTLESS		?= ""

all: libjb_ios.dylib libjb_tvos.dylib

.PHONY : all rootless clean package

%:
    @:
    
libjb_ios.dylib: $(FILES)
	@echo "[i] Building $@..."
	@clang $(FILES) -o $@ $(C_FLAGS_IOS) $(LD_FLAGS_ALL)
	@strip -x $@
	@ldid -S $@
	@mkdir -p ios$(PREFIX)/lib/
	@mkdir -p ios$(PREFIX)/include/
	@cp $@ ios$(PREFIX)/lib/$(TARGET).dylib
	@cp libjb.h ios$(PREFIX)/include/
    
libjb_tvos.dylib: $(FILES)
	@echo "[i] Building $@..."
	@clang $(FILES) -o $@ $(C_FLAGS_TVOS) $(LD_FLAGS_ALL)
	@strip -x $@
	@ldid -S $@
	@mkdir -p tvos$(PREFIX)/lib/
	@mkdir -p tvos$(PREFIX)/include/
	@cp $@ tvos$(PREFIX)/lib/$(TARGET).dylib
	@cp libjb.h tvos$(PREFIX)/include/
    
clean:
	rm -rf libjb_*.dylib ios/usr ios/fs tvos/fs tvos/usr

rootless:
	PREFIX="/fs/jb/usr" ROOTLESS="rootless-"	$(MAKE) clean package
	
package: all
	@echo $(VERSION)
	@echo $(ROOTLESS)
	makedeb ios
	mv ios.deb libjb_1.0-$(VERSION)_$(ROOTLESS)iphoneos-arm.deb
	makedeb tvos
	mv tvos.deb libjb_1.0-$(VERSION)_$(ROOTLESS)appletvos-arm64.deb
	
