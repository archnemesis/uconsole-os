#
# uConsole Buildroot
#

include $(sort $(wildcard $(BR2_EXTERNAL_UCONSOLE_PATH)/package/*/*.mk))
include $(BR2_EXTERNAL_UCONSOLE_PATH)/git-dev.mk

%-git-dev: PKG = $(call UPPERCASE,$*)
%-git-dev: PATCH_BASE_DIRS = $(addsuffix /$*, $(call qstrip,$(BR2_GLOBAL_PATCH_DIR)))
%-git-dev:
	[ ! -d $($(PKG)_DIR) ] || \
	    ( \
	      echo "ERROR: cannot setup $@: $($(PKG)_DIR) already exists"; \
	      exit 1; \
	    )
	# skip GLOBAL_PATCH_DIR patches; we apply them with git-dev-ex instead
	$(MAKE) $*-patch BR2_GLOBAL_PATCH_DIR=
	$(call git-dev-ex, $($(PKG)_DIR), $(addsuffix /$($(PKG)_VERSION), $(PATCH_BASE_DIRS)))

%-git-patches: PKG = $(call UPPERCASE,$*)
%-git-patches:
	# export patches to $BUILD_DIR/<packagename>-git-patches
	$(call git-patches-ex, $($(PKG)_DIR), $($(PKG)_DIR)/../$@)

%-find-lic: PKG = $(call UPPERCASE,$*)
%-find-lic:
	$(MAKE) $*-patch
	( cd $($(PKG)_DIR); \
	licenses=""; \
	printf "# Locally computed\n"; \
	for f in \
	$$( find . -type f \
	    \( -iname 'license*' \
		-o -iname 'copying*' \
		-o -name 'APPLE_LICENSE' \
		-o -name 'Copyright' \
		-o -path '*/license_texts/*' \
		-o -path '*/licenses/*' \
	    \) -a \
	    -not -name '*.cc' \
	    -not -name '*.py' \
	    -not -name '*.pyc' \
	    -not -name '*.h' \
	    -not -name 'LICENSE.sha1' \
	    -not -name 'licensecheck.pl*' \
	    -not -name 'license.after' \
	    -not -name 'license.before' ); \
	do \
	    licenses="$${licenses} $${f##*./}"; \
	    printf "sha256  %s\n" "$$(sha256sum $${f##*./})"; \
	done; \
	printf "$(PKG)_LICENSE_FILES = %s\n" "$${licenses}"; )

bom: legal-info
	BR2_PRIMARY_SITE="$(BR2_PRIMARY_SITE)" \
	$(BR2_EXTERNAL_br2_external_PATH)/support/bom/bom.py > \
	    $(BINARIES_DIR)/bom.csv
