# (C)2004-2010 SourceMod Development Team
# Makefile written by David "BAILOPAN" Anderson

###########################################
### EDIT THESE PATHS FOR YOUR OWN SETUP ###
###########################################

SMSDK = ../sourcemod
HL2SDK_L4D2 = ../hl2sdk
MMSOURCE110 = ../mmsource

#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

ENGINE=left4dead2
PROJECT = AddonsDisabler

#Uncomment for Metamod: Source enabled extension
USEMETA = true

OBJECTS = smsdk_ext.cpp extension.cpp asm/asm.c detours/detour.cpp codepatch/patchmanager.cpp addons_disabler.cpp

##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################

C_OPT_FLAGS = -DNDEBUG -O3 -funroll-loops -pipe -fno-strict-aliasing
C_DEBUG_FLAGS = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS = -fvisibility=hidden
CPP_GCC4_FLAGS = -fvisibility-inlines-hidden
CPP = gcc
CPP_OSX = clang

##########################
### SDK CONFIGURATIONS ###
##########################

override ENGSET = false

# Check for valid list of engines
ifneq (,$(filter left4dead2,$(ENGINE)))
	override ENGSET = true
endif

OS := $(shell uname -s)

ifeq "$(OS)" "Darwin"
	LIB_EXT = dylib
	HL2LIB = $(HL2SDK)/lib/mac
else
	LIB_EXT = so
	HL2LIB = $(HL2SDK)/lib/linux
endif

ifeq "$(ENGINE)" "left4dead2"
	HL2SDK = $(HL2SDK_L4D2)
	CFLAGS += -DSOURCE_ENGINE=13
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.l4d2
endif
HL2PUB = $(HL2SDK)/public

INCLUDE += -I$(HL2SDK)/public/game/server
METAMOD = $(MMSOURCE110)/core

INCLUDE += -I. -I.. -Isdk -I$(SMSDK)/public -I$(SMSDK)/sourcepawn/include -I$(SMSDK)/public/extensions

ifeq "$(USEMETA)" "true"

	ifeq "$(OS)" "Darwin"
		LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib.dylib libtier0.dylib
		ifneq (,$(filter csgo,$(ENGINE)))
			LINK += $(HL2LIB)/interfaces_i486.a
		endif
	else
		ifneq (,$(filter left4dead2,$(ENGINE)))
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib_srv.so libtier0_srv.so
		else ifneq (,$(filter left4dead csgo,$(ENGINE)))
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib.so libtier0.so
			ifneq (,$(filter csgo,$(ENGINE)))
				LINK += $(HL2LIB)/interfaces_i486.a
			endif
		else
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a vstdlib_i486.so tier0_i486.so
		endif

	endif

	INCLUDE += -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/tier0 -I$(HL2PUB)/tier1 -I$(METAMOD) \
		-I$(METAMOD)/sourcehook 
	CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_BLOODYGOODTIME=4 -DSE_EYE=5 \
		-DSE_CSS=6 -DSE_HL2DM=7 -DSE_DODS=8 -DSE_SDK2013=9 -DSE_TF2=10 -DSE_LEFT4DEAD=11 -DSE_NUCLEARDAWN=12 \
		-DSE_LEFT4DEAD2=13 -DSE_ALIENSWARM=14 -DSE_PORTAL2=15 -DSE_BLADE=16 -DSE_INSURGENCY=17 \
		-DSE_CSGO=18 -DSE_DOTA=19
endif

LINK += -m32 -lm -ldl

CFLAGS += -DPOSIX -D_alloca=alloca -DCOMPILER_GCC -Wall -Werror -Wno-overloaded-virtual -Wno-switch -Wno-unused \
	-msse -DSOURCEMOD_BUILD -DHAVE_STDINT_H -m32

ifneq "$(ENGINE)" "sdk2013"
	CFLAGS += -Dstricmp=strcasecmp -Dstrcmpi=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
	-D_snprintf=snprintf -D_vsnprintf=vsnprintf 
endif

CPPFLAGS += -Wno-non-virtual-dtor -fno-exceptions -fno-rtti -std=c++11

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

BINARY = $(PROJECT).ext$(BUILD_SUFFIX).$(LIB_EXT)

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
endif

ifeq "$(USEMETA)" "true"
	BIN_DIR := $(BIN_DIR).$(ENGINE)
endif

ifeq "$(OS)" "Darwin"
	CPP = $(CPP_OSX)
	LIB_EXT = dylib
	CFLAGS += -DOSX -D_OSX
	LINK += -dynamiclib -lstdc++ -mmacosx-version-min=10.5
else
	LIB_EXT = so
	CFLAGS += -D_LINUX
	LINK += -shared
endif

IS_CLANG := $(shell $(CPP) --version | head -1 | grep clang > /dev/null && echo "1" || echo "0")

ifeq "$(IS_CLANG)" "1"
	CPP_MAJOR := $(shell $(CPP) --version | grep clang | sed "s/.*version \([0-9]\)*\.[0-9]*.*/\1/")
	CPP_MINOR := $(shell $(CPP) --version | grep clang | sed "s/.*version [0-9]*\.\([0-9]\)*.*/\1/")
else
	CPP_MAJOR := $(shell $(CPP) -dumpversion >&1 | cut -b1)
	CPP_MINOR := $(shell $(CPP) -dumpversion >&1 | cut -b3)
endif

# If not clang
ifeq "$(IS_CLANG)" "0"
	CFLAGS += -mfpmath=sse -DGNUC
endif

# Clang || GCC >= 4
ifeq "$(shell expr $(IS_CLANG) \| $(CPP_MAJOR) \>= 4)" "1"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

# Clang >= 3 || GCC >= 4.7
ifeq "$(shell expr $(IS_CLANG) \& $(CPP_MAJOR) \>= 3 \| $(CPP_MAJOR) \>= 4 \& $(CPP_MINOR) \>= 7 \| $(CPP_MAJOR) \>= 5)" "1"
	CFLAGS += -Wno-delete-non-virtual-dtor
endif

# OS is Linux and not using clang
ifeq "$(shell expr $(OS) \= Linux \& $(IS_CLANG) \= 0)" "1"
	LINK += -static-libgcc
endif

OBJ_BIN := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

# This will break if we include other Makefiles, but is fine for now. It allows
#  us to make a copy of this file that uses altered paths (ie. Makefile.mine)
#  or other changes without mucking up the original.
MAKEFILE_NAME := $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

all: check
	mkdir -p $(BIN_DIR)
	ln -sf $(SMSDK)/public/smsdk_ext.cpp
	mkdir -p $(BIN_DIR)/codepatch
	mkdir -p $(BIN_DIR)/detours
	if [ "$(USEMETA)" = "true" ]; then \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)vstdlib$(LIB_SUFFIX); \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)tier0$(LIB_SUFFIX); \
	fi
	$(MAKE) -f $(MAKEFILE_NAME) extension

check:
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGSET)" = "false" ]; then \
		echo "You must supply one of the following values for ENGINE:"; \
		echo "left4dead2"; \
		exit 1; \
	fi

extension: check $(OBJ_BIN)
	$(CPP) $(INCLUDE) $(OBJ_BIN) $(LINK) -o $(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f $(MAKEFILE_NAME) all DEBUG=true

default: all

clean: check
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/sdk/*.o
	rm -rf $(BIN_DIR)/$(BINARY)

