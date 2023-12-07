# qtermwidget

QTERMWIDGET_VERSION = 1.3.0
QTERMWIDGET_SOURCE = qtermwidget-$(QTERMWIDGET_VERSION).tar.xz
QTERMWIDGET_SITE = https://github.com/lxqt/qtermwidget/releases/download/$(QTERMWIDGET_VERSION)
QTERMWIDGET_DEPENDENCIES = lxqt-build-tools host-lxqt-build-tools
QTERMWIDGET_LICENSE = BSD-3-Clause LGPL2+
QTERMWIDGET_LICENSE_FILES = LICENSE LICENSE.BSD-3-Clause LICENSE.LGPL2+
QTERMWIDGET_SUPPORTS_IN_SOURCE_BUILD = NO

$(eval $(cmake-package))
$(eval $(host-cmake-package))
