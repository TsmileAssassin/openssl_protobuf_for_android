#!/bin/bash
#
# Copyright 2016 leenjewel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# # read -n1 -p "Press any key to continue..."

set -u

source ./build-android-common.sh

init_log_color

TOOLS_ROOT=$(pwd)

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
pwd_path="$(cd -P "$(dirname "$SOURCE")" && pwd)"

echo pwd_path=${pwd_path}
echo TOOLS_ROOT=${TOOLS_ROOT}

LIB_VERSION="v3.19.2"
LIB_NAME="protobuf-3.19.2"
LIB_DEST_DIR="${pwd_path}/../output/android/protobuf"

#brew install autoconf automake libtool
#echo "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.19.2.tar.gz"

rm -rf "${LIB_DEST_DIR}" "${LIB_NAME}"
[ -f "${LIB_NAME}.tar.gz" ] || curl -L https://github.com/protocolbuffers/protobuf/archive/refs/tags/${LIB_VERSION}.tar.gz >${LIB_NAME}.tar.gz

set_android_toolchain_bin

function configure_make() {

    ARCH=$1
    ABI=$2
    ABI_TRIPLE=$3

    log_info "configure $ABI start..."

    if [ -d "${LIB_NAME}" ]; then
        rm -fr "${LIB_NAME}"
    fi
    tar xfz "${LIB_NAME}.tar.gz"
    pushd .
    cd "${LIB_NAME}"

    ./autogen.sh

    PREFIX_DIR="${pwd_path}/../output/android/protobuf-${ABI}"
    if [ -d "${PREFIX_DIR}" ]; then
        rm -fr "${PREFIX_DIR}"
    fi
    mkdir -p "${PREFIX_DIR}"

    OUTPUT_ROOT=${TOOLS_ROOT}/../output/android/protobuf-${ABI}
    mkdir -p ${OUTPUT_ROOT}/log

    set_android_toolchain "protobuf" "${ARCH}" "${ANDROID_API}"

    export ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
    echo ANDROID_NDK_HOME=${ANDROID_NDK_HOME}

    export CFLAGS=""
    export CXXFLAGS=""
    export LDFLAGS=""
    export CPPFLAGS=""
    android_printf_global_params "$ARCH" "$ABI" "$ABI_TRIPLE" "$PREFIX_DIR" "$OUTPUT_ROOT"

    cd cmake
    export PREFIX=$PREFIX_DIR
    if [[ "${ARCH}" == "x86_64" ]]; then
        cmake -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake -DANDROID_ABI=${ABI} -DANDROID_NATIVE_API_LEVEL=${ANDROID_API} -DCMAKE_BUILD_TYPE=Release -DANDROID_TOOLCHAIN=clang -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR >"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1

    elif [[ "${ARCH}" == "x86" ]]; then
        cmake -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake -DANDROID_ABI=${ABI} -DANDROID_NATIVE_API_LEVEL=${ANDROID_API} -DCMAKE_BUILD_TYPE=Release -DANDROID_TOOLCHAIN=clang -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR >"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1
    elif [[ "${ARCH}" == "arm" ]]; then

        cmake -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake -DANDROID_ABI=${ABI} -DANDROID_NATIVE_API_LEVEL=${ANDROID_API} -DCMAKE_BUILD_TYPE=Release -DANDROID_TOOLCHAIN=clang -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR >"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1

    elif [[ "${ARCH}" == "arm64" ]]; then
        cmake -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake -DANDROID_ABI=${ABI} -DANDROID_NATIVE_API_LEVEL=${ANDROID_API} -DCMAKE_BUILD_TYPE=Release -DANDROID_TOOLCHAIN=clang -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR >"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1

    else
        log_error "not support" && exit 1
    fi

    log_info "make $ABI start..."

    export PREFIX=$PREFIX_DIR
    if make -j$(get_cpu_count) >>"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1; then
        make install >>"${OUTPUT_ROOT}/log/${ABI}.log" 2>&1
    fi

    popd
}

log_info "${PLATFORM_TYPE} ${LIB_NAME} start..."
for ((i = 0; i < ${#ARCHS[@]}; i++)); do
    if [[ $# -eq 0 || "$1" == "${ARCHS[i]}" ]]; then
        configure_make "${ARCHS[i]}" "${ABIS[i]}" "${ARCHS[i]}-linux-android"
    fi
done

log_info "${PLATFORM_TYPE} ${LIB_NAME} end..."
