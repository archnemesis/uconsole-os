#!/bin/sh

cd buildroot
make BR2_EXTERNAL=../ $@
