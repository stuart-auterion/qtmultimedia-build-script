#!/bin/bash

# Setup
###############################################################################
ROOTDIR=$PWD
mkdir $ROOTDIR/src
mkdir $ROOTDIR/build
mkdir $ROOTDIR/install

# GStreamer
###############################################################################
GSTREAMER_VERSION="gstreamer-1.0-android-universal-1.20.5"
# Download
wget -P $ROOTDIR/src/gstreamer/ \
    https://gstreamer.freedesktop.org/data/pkg/android/1.20.5/$GSTREAMER_VERSION.tar.xz
# Extract
tar -xf $ROOTDIR/src/gstreamer/$GSTREAMER_VERSION.tar.xz -C $ROOTDIR/src/gstreamer/
GSTREAMER_ROOT_ANDROID=$ROOTDIR/src/gstreamer
export GSTREAMER_ROOT_ANDROID=$GSTREAMER_ROOT_ANDROID

# Java
###############################################################################
# Install
if false; then
	sudo apt install openjdk-8-jdk
fi
# Define environment variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Qt - setup
###############################################################################
# Install prerequisites
# (see https://wiki.qt.io/Building_Qt_5_from_Git)
if false; then
	# need a better way to do this...
	sudo apt-get install build-essential perl python3 git
	sudo apt-get install '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev \
		libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev
	sudo apt-get install libasound2-dev libgstreamer1.0-dev \
		libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
		libgstreamer-plugins-bad1.0-dev
fi
# Clone
git clone --branch 5.15.2 --depth 1 \
    git@github.com:qt/qt5.git $ROOTDIR/src/qt
cd $ROOTDIR/src/qt
# Only init the submodules we care about
git submodule update --init qtbase
git submodule update --init qtmultimedia

# Qt - qtbase
###############################################################################
# Configure
cd $ROOTDIR/build
$ROOTDIR/src/qt/configure \
	-xplatform android-clang \
    -gstreamer \
    -android-abis arm64-v8a \
	-release \
	-commercial -confirm-license \
	--disable-rpath \
	-nomake tests -nomake examples \
	-android-ndk ~/Qt/Android/ndk/21.3.6528147/ \
	-android-sdk ~/Qt/Android \
	-android-ndk-host linux-x86_64 \
	-skip qtlottie -skip qtpurchasing \
	-no-warnings-are-errors \
	-prefix $ROOTDIR/install \
	-I$GSTREAMER_ROOT_ANDROID/arm64/include/gstreamer-1.0 \
	-I$GSTREAMER_ROOT_ANDROID/arm64/include/glib-2.0 \
	-I$GSTREAMER_ROOT_ANDROID/arm64/lib/glib-2.0/include
# Build qtbase
make -j$(nproc) module-qtbase
# Install qtbase
make -j$(nproc) module-qtbase-install_subtargets

# Qt - qtmultimedia
# (use qtbase to build qtmultimedia)
###############################################################################
# qmake
cd $ROOTDIR/build/qtmultimedia
$ROOTDIR/install/bin/qmake -r \
    $ROOTDIR/src/qt/qtmultimedia/qtmultimedia.pro \
    "LIBS+=-L$GSTREAMER_ROOT_ANDROID/arm64/lib/" \
    "LIBS+=-L$GSTREAMER_ROOT_ANDROID/arm64/lib/gstreamer-1.0/"
# make
make -j$(nproc)
# make install
make -j$(nproc) install

# Done
###############################################################################
cd $ROOTDIR
