#!/bin/bash -x
set -e

# AUTHORS: Dan Liew
#
# BEGIN DATE: Jul, 2014
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECT

# This file wraps CMake invocation for TravisCI
# so we can set different configurations via environment variables.
#
# We could modify our CMake scripts to read environment variables directly but
# that would create two ways of setting the same thing which doesn't seem like
# a good idea.

SOURCE_DIR="$1"
COMMON_CMAKE_ARGS="-G \"Unix Makefiles\" -DENABLE_TESTING:BOOL=ON -DLIT_ARGS:STRING=-v"

# Note eval is needed so COMMON_CMAKE_ARGS is expanded properly
case $STP_CONFIG in
    STATIC_LIB)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DBUILD_SHARED_LIBS:BOOL=OFF \
                   -DBUILD_STATIC_BIN:BOOL=OFF \
                   -DENABLE_PYTHON_INTERFACE:BOOL=OFF \
                   ${SOURCE_DIR}
    ;;

    COVERAGE)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                    -DCOVERAGE:BOOL=ON \
                   ${SOURCE_DIR}
    ;;

    DYNAMIC_LIB)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DBUILD_SHARED_LIBS:BOOL=ON \
                   -DBUILD_STATIC_BIN:BOOL=OFF \
                   -DALSO_BUILD_STATIC_LIB:BOOL=OFF \
                   ${SOURCE_DIR}
    ;;

    DYNAMIC_AND_STATIC_LIB)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DBUILD_SHARED_LIBS:BOOL=ON \
                   -DBUILD_STATIC_BIN:BOOL=OFF \
                   -DALSO_BUILD_STATIC_LIB:BOOL=ON \
                   ${SOURCE_DIR}
    ;;

    STATIC_BINARY)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DBUILD_STATIC_BIN:BOOL=ON \
                   -DENABLE_PYTHON_INTERFACE:BOOL=OFF \
                   ${SOURCE_DIR}
    ;;

    RELEASE)
        eval sudo apt-get install -y libboost-all-dev
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DENABLE_ASSERTIONS:BOOL=OFF \
                   -DCMAKE_BUILD_TYPE:STRING=Release \
                   ${SOURCE_DIR}
    ;;

    NO_BOOST)
        eval cmake ${COMMON_CMAKE_ARGS} \
                   -DNO_BOOSTS:BOOL=ON \
                   ${SOURCE_DIR}
    ;;

    CPP11)
         eval sudo apt-get install -y libboost-all-dev
         export CC="gcc-4.7"
         export CXX="g++-4.7"
         eval sudo add-apt-repository -y ppa:ubuntu-sdk-team/ppa
         eval sudo add-apt-repository -y ppa:george-edison55/gcc4.7-precise
         eval sudo apt-get update
         eval sudo apt-get install -y gcc-4.7 g++-4.7
         eval cmake ${COMMON_CMAKE_ARGS} \
                   -DBUILD_SHARED_LIBS:BOOL=ON \
                   -DBUILD_STATIC_BIN:BOOL=OFF \
                   -DALSO_BUILD_STATIC_LIB:BOOL=OFF \
                   ${SOURCE_DIR}
    ;;

    *)
        echo "\"${STP_CONFIG}\" configuration not recognised"
        exit 1
esac

make VERBOSE=1
make check

# Build example project. We assume that the build installed itself to the CMake
#- mkdir simple_example
#- cd simple_example
#- cmake -G "Unix Makefiles" -DUSE_STP_SHARED_LIBRARY=$( test -f ../stp/lib/libstp.so && echo ON || echo OFF) ../../examples/simple
#- make VERBOSE=1
#- ./stp-example

if [ "$STP_CONFIG" = "COVERAGE" ]; then
  # capture coverage info
  lcov --directory stp/CMakeFiles/temp_lib_norm.dir --capture --output-file coverage.info

  # filter out system and test code
  lcov --remove coverage.info 'tests/*' '/usr/*' --output-file coverage.info

  # debug before upload
  lcov --list coverage.info
  coveralls-lcov --repo-token $COVERTOKEN coverage.info # uploads to coveralls
fi

exit 0
