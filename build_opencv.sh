#!/bin/bash

set -e

export OPENCV_VERSION=4.1.2
export INSTALL_DIR=/usr/local

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    cmake \
    curl \
    git \
    libavcodec-dev \
    libavformat-dev \
    libavresample-dev \
    libdc1394-22-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-0 \
    libgstreamer1.0-dev \
    libgtk2.0-dev \
    libhdf5-dev \
    libjpeg-dev \
    libpng-dev \
    libpython3-dev \
    libssl1.0.0 \
    libtbb-dev \
    libtbb2 \
    libtiff-dev \
    libv4l-dev \
    pkg-config \
    python3-dev \
    python3-numpy \
    qv4l2 \
    v4l-utils \
    v4l2ucp \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-tools \
    libgstrtspserver-1.0-0 \
    libjansson4=2.11-1 \
    libswscale-dev

git clone https://github.com/opencv/opencv.git
pushd opencv
git checkout $OPENCV_VERSION
popd

git clone https://github.com/opencv/opencv_contrib.git
pushd opencv_contrib
git checkout $OPENCV_VERSION
popd

cd opencv

mkdir release && cd release

cmake \
    -D WITH_CUDA=ON \
    -D CPACK_BINARY_DEB=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D WITH_GSTREAMER=ON \
    -D ENABLE_FAST_MATH=ON \
    -D CUDA_FAST_MATH=ON \
    -D WITH_CUBLAS=ON \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER_0_10=OFF \
    -D WITH_LIBV4L=ON \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CPACK_PACKAGING_INSTALL_PREFIX=$INSTALL_DIR \
    -D CMAKE_INSTALL_PREFIX=$INSTALL_DIR ..

make -j$(nproc)

sudo make install

sudo ldconfig

# This creates a bunch of .deb files in the release directory.
sudo make package -j$(nproc)
