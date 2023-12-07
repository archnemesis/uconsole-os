# lxqt-build-tools

LXQT_BUILD_TOOLS_VERSION = 0.13.0
LXQT_BUILD_TOOLS_SOURCE = lxqt-build-tools-$(LXQT_BUILD_TOOLS_VERSION).tar.xz
LXQT_BUILD_TOOLS_SITE = https://github.com/lxqt/lxqt-build-tools/releases/download/$(LXQT_BUILD_TOOLS_VERSION)
LXQT_BUILD_TOOLS_DEPENDENCIES = qt5base host-cmake
LXQT_BUILD_TOOLS_LICENSE = BSD-3-Clause
LXQT_BUILD_TOOLS_LICENSE_FILES = BSD-3-Clause
LXQT_BUILD_TOOLS_SUPPORTS_IN_SOURCE_BUILD = NO
LXQT_BUILD_TOOLS_CONF_OPTS = -DQt5Core_DIR=$(TARGET_CROSS)/sysroot/usr/lib/cmake/Qt5Core

$(eval $(cmake-package))
$(eval $(host-cmake-package))
