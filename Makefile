
ifneq ($(EMSCRIPTEN),)
   platform = emscripten
endif

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

TARGET_NAME := 2048

fpic=
ifeq ($(platform), unix)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
else ifeq ($(platform), ios)
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib
	DEFINES := -DIOS
	CC = clang -arch armv7 -isysroot $(IOSSDK)
else ifeq ($(platform), qnx)
	TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else
   CC = gcc
   TARGET := $(TARGET_NAME)_retro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -Wl,--no-undefined -s
endif

ifeq ($(DEBUG), 1)
   CFLAGS += -O0 -g
else
   CFLAGS += -O3
endif

OBJECTS := libretro.o game.o
CFLAGS += -Wall -pedantic $(fpic)

#packages=cairo
#LFLAGS := $(shell pkg-config --libs-only-L --libs-only-other $(packages))
#LIBS := $(shell pkg-config --libs-only-l $(packages)) -lm
CFLAGS += -Icairo/src -Ipixman/pixman
LFLAGS := 
LIBS := -lm cairo/src/.libs/libcairo.a pixman/pixman/.libs/libpixman-1.a -lpthread -lfreetype -lfontconfig

ifeq ($(platform), qnx)
   CFLAGS += -Wc,-std=gnu99
else
   CFLAGS += -std=gnu99
endif

with_fpic=
ifneq ($(fpic),)
   with_fpic := --with-pic=yes
endif

all: $(TARGET)

$(TARGET): $(OBJECTS) cairo/src/.libs/libcairo.a
	$(CC) $(fpic) $(SHARED) $(INCLUDES) $(LFLAGS) -o $@ $(OBJECTS) $(LIBS)

#pixman_LIBS="../pixman/src/libpixman-1.la" \

pixman/pixman/.libs/libpixman-1.a:
	cd pixman; \
		./configure --enable-shared=no --enable-static=yes $(with_fpic) CFLAGS="-fno-lto"; \
		make; \
		cd ..

cairo/src/.libs/libcairo.a: pixman/pixman/.libs/libpixman-1.a
	cd cairo; \
		./configure --enable-static=yes --enable-ft=yes --enable-shared=no \
			--enable-gobject=no --enable-trace=no --enable-interpreter=no \
			--enable-symbol-lookup=no --enable-svg=no --enable-pdf=no --enable-ps=no \
			--enable-wgl=no --enable-glx=no --enable-egl=no --disable-valgrind \
			--enable-silent-rules --enable-png=no  --enable-xlib=no --enable-win32=no \
			--enable-drm=no --enable-xcb-drm=no --enable-drm-xr=no --disable-lto  \
			--enable-freetype=no $(with_fpic) CFLAGS="-fno-lto" \
			pixman_CFLAGS="-I../../pixman/pixman"; \
		make;\
		cd ..

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

