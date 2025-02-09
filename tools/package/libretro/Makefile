STATIC_LINKING := 0
AR             := ar

ifneq ($(V),1)
   Q := @
endif

ifneq ($(SANITIZER),)
   CFLAGS   := -fsanitize=$(SANITIZER) $(CFLAGS)
   LDFLAGS  := -fsanitize=$(SANITIZER) $(LDFLAGS)
endif

ifeq ($(platform),)
   platform = unix
   ifeq ($(shell uname -s),)
      platform = win
   else ifneq ($(findstring MINGW,$(shell uname -s)),)
      platform = win
   else ifneq ($(findstring Darwin,$(shell uname -s)),)
      platform = osx
   else ifneq ($(findstring win,$(shell uname -s)),)
      platform = win
   endif
endif

# system platform
system_platform = unix
ifeq ($(shell uname -a),)
	EXE_EXT = .exe
	system_platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
	system_platform = osx
	arch = intel
   ifeq ($(shell uname -p),arm)
      arch = arm
   endif
else ifneq ($(findstring MINGW,$(shell uname -a)),)
	system_platform = win
endif

CORE_DIR    += ../../../
VXT_DIR		:= $(CORE_DIR)/lib/vxt
TARGET_NAME := virtualxt
LIBM		    = -lm

ifeq ($(STATIC_LINKING), 1)
   EXT := a
endif

ifeq ($(platform), unix)
	EXT ?= so
   TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else ifeq ($(platform), linux-portable)
   TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC -nostdlib
   SHARED := -shared
	LIBM :=
else ifneq (,$(findstring android,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_android.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
   TARGET_TRIPLE := unknown

   ifeq ($(platform), android-arm)
      TARGET_TRIPLE = armv7a-linux-androideabi
   else ifeq ($(platform), android-arm64)
      TARGET_TRIPLE = aarch64-linux-android
   else ifeq ($(platform), android-x86)
      TARGET_TRIPLE = i686-linux-android
   else ifeq ($(platform), android-x86_64)
      TARGET_TRIPLE = x86_64-linux-android
   endif

   CC = $(ANDROID_NDK_LLVM)/bin/$(TARGET_TRIPLE)21-clang
   AR = $(ANDROID_NDK_LLVM)/bin/llvm-ar

else ifneq (,$(findstring osx,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib

   ifeq ($(CROSS_COMPILE),1)
		TARGET_RULE   = -target $(LIBRETRO_APPLE_PLATFORM) -isysroot $(LIBRETRO_APPLE_ISYSROOT)
		CFLAGS       += $(TARGET_RULE)
		LDFLAGS      += $(TARGET_RULE)
   endif
else ifneq (,$(findstring ios,$(platform)))
	EXT ?= dylib
   TARGET := $(TARGET_NAME)_libretro_ios.$(EXT)
   fpic := -fPIC
   SHARED := -dynamiclib
   DEFINES := -DIOS
   MIN_VERSION := -miphoneos-version-min=5.0

   ifeq ($(platform),$(filter $(platform),ios9 ios-arm64))
      MIN_VERSION = -miphoneos-version-min=8.0
   endif
   ifeq ($(IOSSDK),)
      IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
   endif

   ifeq ($(platform),ios-arm64)
      SHARED += -arch arm64 $(MIN_VERSION) -isysroot $(IOSSDK)
      CC = cc -arch arm64 $(MIN_VERSION) -isysroot $(IOSSDK)
   else
      SHARED += -arch armv7 $(MIN_VERSION) -isysroot $(IOSSDK)
      CC = cc -arch armv7 $(MIN_VERSION) -isysroot $(IOSSDK)
   endif
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -s -Wl,--no-undefined
endif

LDFLAGS += $(LIBM)

ifeq ($(DEBUG), 1)
   CFLAGS += -O0 -g
else
   CFLAGS += -O3 -DNDEBUG
endif

include Makefile.common

OBJECTS := $(SOURCES_C:.c=.o)
CFLAGS += -Wall -D__LIBRETRO__ $(fpic)

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	@$(if $(Q), $(shell echo echo LD $@),)
	$(Q)$(CC) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS)
endif

%.o: %.c
	@$(if $(Q), $(shell echo echo CC $<),)
	$(Q)$(CC) $(CFLAGS) $(fpic) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

print-%:
	@echo '$*=$($*)'
