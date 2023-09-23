#!/bin/sh

TARGET=$1
UCONSOLE_SDK_VERSION="1.0.0"
GIT_REV=$(git rev-parse HEAD)

case "${TARGET}" in
	"sdk")
		(
			cd buildroot
			make BR2_EXTERNAL=../ prepare-sdk
		)

		(
			cd sdk

			# Clean up previous build files
			rm -rf uconsole-sdk-* uconsole-sdk_*
			
			# Create deb package
			cp -rv uconsole-sdk uconsole-sdk-$UCONSOLE_SDK_VERSION
			cd uconsole-sdk-$UCONSOLE_SDK_VERSION
			find . -type f -print0 | xargs -0 sed -i -e "s/@BUILD_DATE@/$(date --iso-8601=seconds)/g"
			find . -type f -print0 | xargs -0 sed -i -e "s/@BUILD_HOST@/$(hostname)/g"
			find . -type f -print0 | xargs -0 sed -i -e "s/@SDK_VERSION@/${UCONSOLE_SDK_VERSION}/g"
			find . -type f -print0 | xargs -0 sed -i -e "s/@GIT_SHA@/${GIT_REV}/g"
			dpkg-buildpackage -us -uc
		)
		;;
	*)
		cd buildroot
		make BR2_EXTERNAL=../ $@
		;;
esac
