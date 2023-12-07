# Copyright (C) 2021 Tektronix Inc.
#
# git-dev.mk - util functions for patching packages using 'git format-patch'
#
# Adapted from git-dev-ex/git-patches-ex functions used in TPInux Linux.
#
# TPInux was developed by TriplePoint Inc., and provided to Tektronix
# under the following license:
#
#   Copyright (c) TriplePoint, Inc. -- http://www.TriplePoint.com
#   All rights reserved.
#
#   This source code may be used by anyone provided the TriplePoint copyright
#   statement is retained in any derivative works.
#

#############################################################################
# Function: git-dev-ex
# arg1 = project source directory
# arg2 = list of directories containing patch files
# Description:
#  Add project source to a temporary git repo, and apply patches using git.

define git-dev-ex
( \
    set -e; \
    set -x; \
    PROJECT_DIR="$(strip $(1))"; \
    PATCH_DIRS="$(strip $(2))"; \
    cd "$${PROJECT_DIR}"; \
    find . -name .gitignore -print0 | xargs -0 rm -f; \
    git init; \
    git add --all .; \
    git -c gc.auto=0 commit --quiet -m'Initial version'; \
    git tag -m'Initial' Initial; \
    git gc --force; \
    for d in $${PATCH_DIRS}; do \
        if [ -d "$${d}" ]; then \
            for patch in $${d}/*.patch; do \
                [ -f "$${patch}" ] && \
                    git am --keep-cr "$${patch}"; \
            done; \
        fi; \
    done; \
    git gc --force; \
)
endef

#############################################################################
# Function: git-patches-ex
# arg1 = project source directory
# arg2 = output directory for exported patch files
# Description:
#  Export patch files from a git-dev project directory.

define git-patches-ex
( \
    set -e; \
    set -x; \
    PROJECT_DIR="$(strip $(1))"; \
    OUT_DIR="$(strip $(2))"; \
    cd "$${PROJECT_DIR}"; \
    git format-patch -o "$${OUT_DIR}" Initial; \
)
endef
