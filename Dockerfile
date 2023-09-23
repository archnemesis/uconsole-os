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
  debhelper
