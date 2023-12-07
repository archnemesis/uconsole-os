BUILDROOT_VERSION = 2023.08.3
BUILDROOT_SOURCE = buildroot-$(BUILDROOT_VERSION).tar.gz
BUILDROOT_SITE = http://buildroot.org/downloads
BUILDROOT_DIR = $(CURDIR)/buildroot-$(BUILDROOT_VERSION)
BUILDROOT_SHA256 = be164316d1847928f8d08b281f44aa6ca6cea02b2957baf1a7cf7f3994d26348
BUILDROOT_DL_DIR = $(BUILDROOT_BR2_DL_DIR)/buildroot
BUILDROOT_PATCH_DIR = $(CURDIR)/patches/buildroot/$(BUILDROOT_VERSION)
BUILDROOT_BR2_EXTERNAL = $(CURDIR)
BUILDROOT_BR2_DL_DIR ?= $(CURDIR)/dl

include git-dev.mk

# 'all' target is used by buildroot sub-project, so don't override it
.PHONY: _all
_all: $(BUILDROOT_DIR)/.stamp_patched

$(BUILDROOT_DL_DIR)/$(BUILDROOT_SOURCE):
	mkdir -p $$(dirname $@)
	curl -L $(BUILDROOT_SITE)/$(BUILDROOT_SOURCE) > $@.tmp
	if echo $(BUILDROOT_SHA256) *$@.tmp | sha256sum -c; then \
	    mv $@.tmp $@; \
	else \
	    exit 1; \
	fi

.PHONY: buildroot-source
buildroot-source: $(BUILDROOT_DL_DIR)/$(BUILDROOT_SOURCE)

$(BUILDROOT_DIR)/.stamp_extracted: $(BUILDROOT_DL_DIR)/$(BUILDROOT_SOURCE)
	mkdir -p $(BUILDROOT_DIR)
	tar -C $(BUILDROOT_DIR) --strip-components=1 \
	    -xf $(BUILDROOT_DL_DIR)/$(BUILDROOT_SOURCE)
	ln -sf $$(basename $(BUILDROOT_DIR)) buildroot
	cat /dev/null > $@

.PHONY: buildroot-extract
buildroot-extract: $(BUILDROOT_DIR)/.stamp_extracted

$(BUILDROOT_DIR)/.stamp_patched: $(BUILDROOT_DIR)/.stamp_extracted
	for d in $(BUILDROOT_PATCH_DIR); do \
	    if [ -d "$${d}" ]; then \
	        for patch in $${d}/*.patch; do \
	            if [ -f "$${patch}" ]; then \
	                cat $${patch} | patch -d $(BUILDROOT_DIR) -f -p1; \
	            fi; \
	        done; \
	    fi; \
	done
	cat /dev/null > $@

.PHONY: buildroot-patch
buildroot-patch: $(BUILDROOT_DIR)/.stamp_patched

$(BUILDROOT_DIR)/.stamp_git_dev:
	[ ! -d "$(BUILDROOT_DIR)" ] || \
	    ( \
	      echo "ERROR: cannot setup $@: $(BUILDROOT_DIR) already exists"; \
	      exit 1; \
	    )
	# skip BUILDROOT_PATCH_DIR patches; we apply them with git-dev-ex instead
	$(MAKE) buildroot-patch BUILDROOT_PATCH_DIR=
	$(call git-dev-ex, $(BUILDROOT_DIR), $(BUILDROOT_PATCH_DIR))
	cat /dev/null > $@

.PHONY: buildroot-git-dev
buildroot-git-dev: $(BUILDROOT_DIR)/.stamp_git_dev

buildroot-git-patches: $(BUILDROOT_DIR)/.stamp_git_dev
	$(call git-patches-ex, $(BUILDROOT_DIR), $(BUILDROOT_DIR)/../$@)

# (terminal) match-anything rule
%:: $(BUILDROOT_DIR)/.stamp_patched
	$(MAKE) -C $(BUILDROOT_DIR) \
	    BR2_EXTERNAL="$(BUILDROOT_BR2_EXTERNAL)" \
	    BR2_DL_DIR="$(BUILDROOT_BR2_DL_DIR)" \
	    $(MAKECMDGOALS)

# start an interactive subshell (e.g. to debug build environment)
.PHONY: sh bash
sh bash:
	$@

.PHONY: clean
clean:
	rm -rf $(BUILDROOT_DIR)
	rm -rf buildroot

.PHONY: clobber
clobber: clean
	rm -rf $(BUILDROOT_BR2_DL_DIR)

# cancel implicit rules that conflict with match-anything rule(s)
$(MAKEFILE_LIST): ;
