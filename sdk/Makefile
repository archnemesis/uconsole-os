#
# Copyright (C) 2020-2023 Tektronix Inc.
#

#############################################################################
# Function: find_and_replace
# arg1 = old text (i.e. text to be replaced)
# arg2 = new text
# Description:
#  Find and replace all occurrences of specified text in current working
#  directory (and all subdirectories).

define find_and_replace
(                                                                            \
    set -e;                                                                  \
                                                                             \
    OLDTEXT="$(strip $(1))";                                                 \
    NEWTEXT="$(strip $(2))";                                                 \
                                                                             \
    export LC_ALL=C;                                                         \
    grep -lr "$${OLDTEXT}" . | while read -r FILE ; do                       \
        if file -b --mime-type "$${FILE}" | grep -q '^text/'; then           \
            sed -i "s|$${OLDTEXT}|$${NEWTEXT}|g" "$${FILE}";                 \
        fi;                                                                  \
    done;                                                                    \
)
endef

BUILD_NUMBER = 0

ifeq ($(BUILD_NUMBER),)
	UCONSOLE_SDK_VERSION = 0.0.0
else
	UCONSOLE_SDK_VERSION = 1.1.$(BUILD_NUMBER)
endif

BUILD_DATE = $(shell date --iso-8601=seconds)
BUILD_HOST = $(shell hostname)
GIT_SHA = $(shell git rev-parse HEAD)

all: ;

.PHONY: uconsole-sdk
uconsole-sdk:
	mkdir -p uconsole-sdk-$(UCONSOLE_SDK_VERSION)
	cp -R uconsole-sdk/. uconsole-sdk-$(UCONSOLE_SDK_VERSION)/.

	( cd uconsole-sdk-$(UCONSOLE_SDK_VERSION); \
	    $(call find_and_replace, "@BUILD_DATE@", $(BUILD_DATE)); \
	    $(call find_and_replace, "@BUILD_HOST@", $(BUILD_HOST)); \
	    $(call find_and_replace, "@GIT_SHA@", $(GIT_SHA)); \
	    $(call find_and_replace, "@SDK_VERSION@", $(UCONSOLE_SDK_VERSION)); \
	    dpkg-buildpackage -us -uc; \
	)

clean:
	rm -rf uconsole-sdk-*
	rm -f *.buildinfo
	rm -f *.changes
	rm -f *.dsc
	rm -f *.tar.gz

clobber: clean
	rm -f *.deb
