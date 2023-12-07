FROM ubuntu:22.04

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
  build-essential \
  libncurses5-dev \
  wget \
  file \
  cpio \
  unzip \
  rsync \
  bc \
  locales \
  git \
  debhelper \
  curl \
  locales

RUN locale-gen en_US.UTF-8
RUN update-locale

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV BUILD_USER build

RUN echo "${BUILD_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ARG BUILD_UID
ARG BUILD_GID

RUN groupadd ${BUILD_GID:+-g ${BUILD_GID}} ${BUILD_USER}
RUN useradd ${BUILD_UID:+-u ${BUILD_UID}} -g ${BUILD_USER} -m ${BUILD_USER}

USER ${BUILD_USER}
