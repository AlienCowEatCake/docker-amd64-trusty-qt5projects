FROM ubuntu:14.04

RUN groupadd --gid 1000 user && \
    useradd --shell /bin/bash --home-dir /home/user --uid 1000 --gid 1000 --create-home user

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get -o Acquire::Check-Valid-Until=false --yes --allow-unauthenticated dist-upgrade && \
    apt-get -o Acquire::Check-Valid-Until=false install --yes --allow-unauthenticated --no-install-recommends \
        wget build-essential fakeroot debhelper libgl1-mesa-dev libx11-xcb-dev \
        libxkbcommon-dev libgtk-3-dev libfontconfig1-dev libfreetype6-dev libdbus-1-dev libcups2-dev \
        libpulse-dev libasound2-dev libgtk2.0-dev libxkbcommon-x11-dev \
        gperf bison ruby flex \
        libssl-dev \
        curl git openssh-client && \
    apt-get clean

WORKDIR /usr/src

ENV PATH="/opt/clang/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/clang/lib:/opt/qt5/lib"
ENV LANG="C.UTF-8"

RUN export CMAKE_VERSION="3.29.8" && \
    wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -xvpf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./configure --prefix=/opt/cmake --no-qt-gui --parallel=$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    ln -s /opt/cmake/bin/cmake /usr/local/bin/ && \
    ln -s /opt/cmake/bin/ctest /usr/local/bin/ && \
    ln -s /opt/cmake/bin/cpack /usr/local/bin/ && \
    cd .. && \
    rm -rf cmake-${CMAKE_VERSION}.tar.gz cmake-${CMAKE_VERSION}

RUN export NINJA_VERSION="1.12.1" && \
    wget --no-check-certificate https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz && \
    tar -xvpf v${NINJA_VERSION}.tar.gz && \
    cd ninja-${NINJA_VERSION} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S . -B build \
            -G "Unix Makefiles" \
            -DCMAKE_BUILD_TYPE=Release && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build --target ninja -- -j$(getconf _NPROCESSORS_ONLN) && \
    strip --strip-all build/ninja && \
    cp -a build/ninja /usr/local/bin/ && \
    cd .. && \
    rm -rf v${NINJA_VERSION}.tar.gz ninja-${NINJA_VERSION}

RUN export CLANG_VERSION="15.0.7" && \
    export CLANG_STAGE1_VERSION="9.0.1" && \
    wget --no-check-certificate https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${CLANG_STAGE1_VERSION}.tar.gz && \
    tar -xvpf llvmorg-${CLANG_STAGE1_VERSION}.tar.gz && \
    cd llvm-project-llvmorg-${CLANG_STAGE1_VERSION} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S llvm -B build \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON \
            -DLLVM_ENABLE_PROJECTS="clang" && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build --target all && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S libcxxabi -B build_libcxxabi \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER="${PWD}/build/bin/clang" \
            -DCMAKE_CXX_COMPILER="${PWD}/build/bin/clang++" \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_EXE_LINKER_FLAGS="-fPIC" \
            -DCMAKE_SHARED_LINKER_FLAGS="-fPIC" \
            -DLLVM_PATH="${PWD}/llvm" \
            -DLIBCXXABI_LIBCXX_PATH="${PWD}/libcxx" \
            -DLIBCXXABI_ENABLE_SHARED=OFF && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build_libcxxabi --target all && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S libcxx -B build_libcxx \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER="${PWD}/build/bin/clang" \
            -DCMAKE_CXX_COMPILER="${PWD}/build/bin/clang++" \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_EXE_LINKER_FLAGS="-L${PWD}/build_libcxxabi/lib -fPIC" \
            -DCMAKE_SHARED_LINKER_FLAGS="-L${PWD}/build_libcxxabi/lib -fPIC" \
            -DLLVM_PATH="${PWD}/llvm" \
            -DLIBCXX_CXX_ABI_INCLUDE_PATHS="${PWD}/libcxxabi/include" \
            -DLIBCXX_CXX_ABI=libcxxabi \
            -DLIBCXX_ENABLE_SHARED=OFF && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build_libcxx --target all && \
    cd .. && \
    \
    wget --no-check-certificate https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${CLANG_VERSION}.tar.gz && \
    tar -xvpf llvmorg-${CLANG_VERSION}.tar.gz && \
    cd llvm-project-llvmorg-${CLANG_VERSION} && \
    sed -i 's|\(virtual unsigned GetDefaultDwarfVersion() const { return \)5;|\14;|' clang/include/clang/Driver/ToolChain.h && \
    sed -i 's|^\(unsigned ToolChain::GetDefaultDwarfVersion() const {\)|\1\n  return 4;|' clang/lib/Driver/ToolChain.cpp && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S llvm -B build \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER="$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build/bin)/clang" \
            -DCMAKE_CXX_COMPILER="$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build/bin)/clang++" \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-I$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/libcxx/include) -I$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/libcxxabi/include) -stdlib=libc++ -fPIC" \
            -DCMAKE_EXE_LINKER_FLAGS="-L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxx/lib) -L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxxabi/lib) -stdlib=libc++ -Wl,--whole-archive -Wl,-Bstatic -lc++ -lc++abi -Wl,-Bdynamic -Wl,--no-whole-archive -lpthread -fPIC" \
            -DCMAKE_SHARED_LINKER_FLAGS="-L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxx/lib) -L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxxabi/lib) -stdlib=libc++ -Wl,--whole-archive -Wl,-Bstatic -lc++ -lc++abi -Wl,-Bdynamic -Wl,--no-whole-archive -lpthread -fPIC" \
            -DCMAKE_MODULE_LINKER_FLAGS="-L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxx/lib) -L$(readlink -f ../llvm-project-llvmorg-${CLANG_STAGE1_VERSION}/build_libcxxabi/lib) -stdlib=libc++ -Wl,--whole-archive -Wl,-Bstatic -lc++ -lc++abi -Wl,-Bdynamic -Wl,--no-whole-archive -lpthread -fPIC" \
            -DLLVM_ENABLE_PROJECTS="clang;lld" \
            -DLLVM_INCLUDE_TESTS=OFF \
            -DLLVM_INCLUDE_DOCS=OFF \
            -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
            -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
            -DCMAKE_INSTALL_PREFIX="/opt/clang" && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build --target all && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --install build --prefix "/opt/clang" && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S runtimes -B build_runtimes \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER="/opt/clang/bin/clang" \
            -DCMAKE_CXX_COMPILER="/opt/clang/bin/clang++" \
            -DLLVM_USE_LINKER=lld \
            -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
            -DLLVM_INCLUDE_TESTS=OFF \
            -DLLVM_INCLUDE_DOCS=OFF \
            -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
            -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
            -DCMAKE_INSTALL_PREFIX="/opt/clang" && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build_runtimes --target cxx cxxabi unwind && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build_runtimes --target install-cxx install-cxxabi install-unwind && \
    cd .. && \
    \
    rm -rf llvmorg-${CLANG_STAGE1_VERSION}.tar.gz llvm-project-llvmorg-${CLANG_STAGE1_VERSION} llvmorg-${CLANG_VERSION}.tar.gz llvm-project-llvmorg-${CLANG_VERSION}

RUN export OPENSSL_VERSION="1.1.1w" && \
    wget --no-check-certificate https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -xvpf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./Configure linux-$(gcc -dumpmachine | sed 's|-.*||' | sed 's|^i686$|x86| ; s|^arm$|armv4| ; s|^powerpc64le$|ppc64le|') --prefix=/opt/qt5 --openssldir=/etc/ssl zlib no-shared && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make depend && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd .. && \
    rm -rf openssl-${OPENSSL_VERSION}.tar.gz openssl-${OPENSSL_VERSION}

RUN export ICU_VERSION="67_1" && \
    wget --no-check-certificate https://github.com/unicode-org/icu/releases/download/release-$(echo ${ICU_VERSION} | sed 's|_|-|g')/icu4c-${ICU_VERSION}-src.tgz && \
    tar -xvpf icu4c-${ICU_VERSION}-src.tgz && \
    cd icu/source && \
    CC="/opt/clang/bin/clang" \
    CXX="/opt/clang/bin/clang++" \
    CPP="/opt/clang/bin/clang++ -E" \
    CFLAGS="-fPIC" \
    CPPFLAGS="-stdlib=libc++ -fPIC" \
    CXXFLAGS="-stdlib=libc++ -fPIC" \
    LDFLAGS="-stdlib=libc++ -lc++ -lc++abi -fPIC -fuse-ld=lld" \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./configure --prefix=/opt/icu --disable-shared --enable-static --disable-tests --disable-samples --with-data-packaging=static && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd ../.. && \
    rm -rf icu icu4c-${ICU_VERSION}-src.tgz

RUN export LIBXML2_VERSION="2.13.4" && \
    wget --no-check-certificate https://download.gnome.org/sources/libxml2/$(echo ${LIBXML2_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/libxml2-${LIBXML2_VERSION}.tar.xz && \
    tar -xvpf libxml2-${LIBXML2_VERSION}.tar.xz && \
    cd libxml2-${LIBXML2_VERSION} && \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig" \
    CC="/opt/clang/bin/clang" \
    CXX="/opt/clang/bin/clang++" \
    CPP="/opt/clang/bin/clang++ -E" \
    CPPFLAGS="-I/opt/icu/include -stdlib=libc++" \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-L/opt/icu/lib -stdlib=libc++ -lc++ -lc++abi -fuse-ld=lld" \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./configure --prefix=/opt/libxml2 --disable-shared --enable-static --with-pic --without-debug --without-docbook --without-python --without-iconv --with-icu && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd .. && \
    rm -rf libxml2-${LIBXML2_VERSION} libxml2-${LIBXML2_VERSION}.tar.xz

RUN export LIBXSLT_VERSION="1.1.42" && \
    wget --no-check-certificate https://download.gnome.org/sources/libxslt/$(echo ${LIBXSLT_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/libxslt-${LIBXSLT_VERSION}.tar.xz && \
    tar -xvpf libxslt-${LIBXSLT_VERSION}.tar.xz && \
    cd libxslt-${LIBXSLT_VERSION} && \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig:/opt/libxml2/lib/pkgconfig" \
    CC="/opt/clang/bin/clang" \
    CXX="/opt/clang/bin/clang++" \
    CPP="/opt/clang/bin/clang++ -E" \
    CPPFLAGS="-I/opt/icu/include -I/opt/libxml2/include -stdlib=libc++" \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-L/opt/icu/lib -L/opt/libxml2/lib -stdlib=libc++ -lc++ -lc++abi -fuse-ld=lld" \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./configure --prefix=/opt/libxslt --disable-shared --enable-static --with-pic --without-python --without-debug --without-debugger --without-profiler && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd .. && \
    rm -rf libxslt-${LIBXSLT_VERSION}.tar.xz libxslt-${LIBXSLT_VERSION}

RUN export QT_XCB_VERSION="5.14.2" && \
    wget --no-check-certificate https://github.com/qt/qtbase/archive/refs/tags/v${QT_XCB_VERSION}.tar.gz && \
    tar -xvpf v${QT_XCB_VERSION}.tar.gz && \
    cd qtbase-${QT_XCB_VERSION}/src/3rdparty/xcb && \
    mkdir -p /opt/xcb/lib && \
    cp -a include /opt/xcb/ && \
    cp -a sysinclude/* /opt/xcb/include/ && \
    for i in $(find . -name '*.c') ; do \
        echo "${i}" && \
        gcc -O3 -DNDEBUG -fPIC -Iinclude -Iinclude/xcb -Isysinclude -c "${i}" -o "$(echo ${i} | sed 's|\.c$|.o|')" ; \
    done && \
    ar rcs /opt/xcb/lib/libxcb-randr.a libxcb/randr.o && \
    ar rcs /opt/xcb/lib/libxcb-render.a libxcb/render.o && \
    ar rcs /opt/xcb/lib/libxcb-shape.a libxcb/shape.o && \
    ar rcs /opt/xcb/lib/libxcb-shm.a libxcb/shm.o && \
    ar rcs /opt/xcb/lib/libxcb-sync.a libxcb/sync.o && \
    ar rcs /opt/xcb/lib/libxcb-xfixes.a libxcb/xfixes.o && \
    ar rcs /opt/xcb/lib/libxcb-xinerama.a libxcb/xinerama.o && \
    ar rcs /opt/xcb/lib/libxcb-xinput.a libxcb/xinput.o && \
    ar rcs /opt/xcb/lib/libxcb-xkb.a libxcb/xkb.o && \
    ar rcs /opt/xcb/lib/libxcb-util.a xcb-util/*.o && \
    ar rcs /opt/xcb/lib/libxcb-image.a xcb-util-image/*.o && \
    ar rcs /opt/xcb/lib/libxcb-keysyms.a xcb-util-keysyms/*.o && \
    ar rcs /opt/xcb/lib/libxcb-render-util.a xcb-util-renderutil/*.o && \
    ar rcs /opt/xcb/lib/libxcb-icccm.a xcb-util-wm/*.o && \
    cd ../../../.. && \
    echo '#if !defined (__XKB_H_HOTFIX)' >> /opt/xcb/include/xcb/xkb.h && \
    echo '#define __XKB_H_HOTFIX' >> /opt/xcb/include/xcb/xkb.h && \
    echo '#if defined (__cplusplus)' >> /opt/xcb/include/xcb/xkb.h && \
    echo 'static inline int xcb_xkb_get_kbd_by_name_replies_key_names_value_list_sizeof(const void *_buffer, uint8_t nTypes, uint32_t indicators, uint16_t virtualMods, uint8_t groupNames, uint8_t nKeys, uint8_t nKeyAliases, uint8_t nRadioGroups, uint32_t which)' >> /opt/xcb/include/xcb/xkb.h && \
    echo '{' >> /opt/xcb/include/xcb/xkb.h && \
    echo '    return xcb_xkb_get_kbd_by_name_replies_key_names_value_list_sizeof(_buffer, nTypes, indicators, virtualMods, groupNames, nKeys, nKeyAliases, nRadioGroups, which);' >> /opt/xcb/include/xcb/xkb.h && \
    echo '}' >> /opt/xcb/include/xcb/xkb.h && \
    echo '#endif' >> /opt/xcb/include/xcb/xkb.h && \
    echo '#endif' >> /opt/xcb/include/xcb/xkb.h && \
    rm -rf v${QT_XCB_VERSION}.tar.gz qtbase-${QT_XCB_VERSION}

RUN export QT_VERSION="5.15.15" && \
    export QT_XKB_COMPOSE_PATCH_VERSION="5.15.6" && \
    export QT_WEBKIT_VERSION="5.212.0-alpha4" && \
    wget --no-check-certificate https://github.com/AlienCowEatCake/qtbase/compare/v${QT_XKB_COMPOSE_PATCH_VERSION}-lts-lgpl...feature/old-compose-input-context_v${QT_XKB_COMPOSE_PATCH_VERSION}.diff -O qtbase_old-compose-input-context_v${QT_XKB_COMPOSE_PATCH_VERSION}.patch && \
    wget --no-check-certificate --tries=1 https://download.qt.io/archive/qt/$(echo ${QT_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz || \
    wget --no-check-certificate --tries=1 https://qt-mirror.dannhauer.de/archive/qt/$(echo ${QT_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz || \
    wget --no-check-certificate --tries=1 https://mirror.accum.se/mirror/qt.io/qtproject/archive/qt/$(echo ${QT_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz || \
    wget --no-check-certificate --tries=1 https://www.nic.funet.fi/pub/mirrors/download.qt-project.org/archive/qt/$(echo ${QT_VERSION} | sed 's|\([0-9]*\.[0-9]*\)\..*|\1|')/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz && \
    wget --no-check-certificate https://github.com/qtwebkit/qtwebkit/releases/download/qtwebkit-${QT_WEBKIT_VERSION}/qtwebkit-${QT_WEBKIT_VERSION}.tar.xz && \
    tar -xvpf qt-everywhere-opensource-src-${QT_VERSION}.tar.xz && \
    cd qt-everywhere-src-${QT_VERSION}/qtbase && \
    patch -p1 -i ../../qtbase_old-compose-input-context_v${QT_XKB_COMPOSE_PATCH_VERSION}.patch && \
    sed -i 's|\(QMAKE_LFLAGS[ ]*+=\)|\1 -fuse-ld=lld|' mkspecs/linux-clang-libc++/qmake.conf && \
    sed -i 's/\(    ffdflags |= FFD_USE_FORK;\)/\1\n\1/' src/corelib/io/qprocess_unix.cpp && \
    sed -i 's|\(#include <ft2build\.h>\)|#if defined (__clang__) \&\& (__clang_major__ >= 5)\n#pragma clang diagnostic push\n#pragma clang diagnostic ignored "-Wregister"\n#endif\n\1|' src/platformsupport/fontdatabases/freetype/qfontengine_ft_p.h && \
    sed -i 's|\(#include FT_FREETYPE_H\)|\1\n#if defined (__clang__) \&\& (__clang_major__ >= 5)\n#pragma clang diagnostic pop\n#endif|' src/platformsupport/fontdatabases/freetype/qfontengine_ft_p.h && \
    cd .. && \
    mkdir build && \
    cd build && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ../configure -prefix /opt/qt5 -opensource -confirm-license \
            -release -strip -shared -platform linux-clang-libc++ -c++std c++17 -linker lld \
            -gui -widgets -dbus-linked -accessibility \
            -qt-doubleconversion -glib -no-icu -qt-pcre -system-zlib \
            -ssl -openssl-linked -no-libproxy -system-proxies \
            -cups -fontconfig -system-freetype -qt-harfbuzz -gtk -opengl desktop -no-opengles3 -no-egl -qpa xcb -xcb-xlib \
            -no-directfb -no-eglfs -no-gbm -no-kms -no-linuxfb -xcb \
            -no-libudev -no-evdev -no-libinput -no-mtdev -no-tslib -bundled-xcb-xinput -xkbcommon \
            -gif -ico -qt-libpng -qt-libjpeg \
            -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite2 -sql-sqlite -no-sql-tds -qt-sqlite \
            -qt-tiff -qt-webp \
            -pulseaudio -alsa -no-gstreamer \
            -no-compile-examples -nomake examples -nomake tests \
            -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
            -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation -skip qtlottie \
            -skip qtmacextras -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d -skip qtquickcontrols \
            -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects -skip qtscript -skip qtscxml \
            -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtvirtualkeyboard \
            -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin -skip qtwebsockets \
            -skip qtwebview -skip qtwinextras -skip qtxmlpatterns -no-feature-qdoc \
            -D _LIBCPP_ENABLE_CXX20_REMOVED_TYPE_TRAITS \
            OPENSSL_PREFIX=/opt/qt5 OPENSSL_LIBS='-lssl -lcrypto -lz -ldl -pthread' \
            XCB_ICCCM_PREFIX=/opt/xcb XCB_ICCCM_LIBS='/opt/xcb/lib/libxcb-icccm.a' \
            XCB_IMAGE_PREFIX=/opt/xcb XCB_IMAGE_LIBS='/opt/xcb/lib/libxcb-image.a /opt/xcb/lib/libxcb-util.a' \
            XCB_KEYSYMS_PREFIX=/opt/xcb XCB_KEYSYMS_LIBS='/opt/xcb/lib/libxcb-keysyms.a' \
            XCB_RANDR_PREFIX=/opt/xcb XCB_RANDR_LIBS='/opt/xcb/lib/libxcb-randr.a' \
            XCB_RENDER_PREFIX=/opt/xcb XCB_RENDER_LIBS='/opt/xcb/lib/libxcb-render.a' \
            XCB_RENDERUTIL_PREFIX=/opt/xcb XCB_RENDERUTIL_LIBS='/opt/xcb/lib/libxcb-render-util.a' \
            XCB_SHAPE_PREFIX=/opt/xcb XCB_SHAPE_LIBS='/opt/xcb/lib/libxcb-shape.a' \
            XCB_SHM_PREFIX=/opt/xcb XCB_SHM_LIBS='/opt/xcb/lib/libxcb-shm.a' \
            XCB_SYNC_PREFIX=/opt/xcb XCB_SYNC_LIBS='/opt/xcb/lib/libxcb-sync.a' \
            XCB_XFIXES_PREFIX=/opt/xcb XCB_XFIXES_LIBS='/opt/xcb/lib/libxcb-xfixes.a' \
            XCB_XINERAMA_PREFIX=/opt/xcb XCB_XINERAMA_LIBS='/opt/xcb/lib/libxcb-xinerama.a' \
            XCB_XINPUT_PREFIX=/opt/xcb XCB_XINPUT_LIBS='/opt/xcb/lib/libxcb-xinput.a' \
            XCB_XKB_PREFIX=/opt/xcb XCB_XKB_LIBS='/opt/xcb/lib/libxcb-xkb.a' \
            QMAKE_CC=/opt/clang/bin/clang \
            QMAKE_CXX=/opt/clang/bin/clang++ \
            QMAKE_LINK_C=/opt/clang/bin/clang \
            QMAKE_LINK_C_SHLIB=/opt/clang/bin/clang \
            QMAKE_LINK=/opt/clang/bin/clang++ \
            QMAKE_LINK_SHLIB=/opt/clang/bin/clang++ && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd .. && \
    tar -xvpf ../qtwebkit-${QT_WEBKIT_VERSION}.tar.xz && \
    cd qtwebkit-${QT_WEBKIT_VERSION} && \
    echo 'set(ICU_LIBRARIES "/opt/icu/lib/libicui18n.a;/opt/icu/lib/libicuuc.a;/opt/icu/lib/libicudata.a")' >> Source/cmake/FindICU.cmake && \
    echo 'set(ICU_I18N_LIBRARIES "/opt/icu/lib/libicui18n.a;/opt/icu/lib/libicuuc.a;/opt/icu/lib/libicudata.a")' >> Source/cmake/FindICU.cmake && \
    sed -i 's|\(parseErrorFunc(void\* userData,\) \(xmlError\)|\1 const \2|' Source/WebCore/xml/XSLTProcessor.h && \
    sed -i 's|\(parseErrorFunc(void\* userData,\) \(xmlError\)|\1 const \2|' Source/WebCore/xml/XSLTProcessorLibxslt.cpp && \
    mkdir build && \
    cd build && \
    SQLITE3SRCDIR=${PWD}/../../qtbase/src/3rdparty/sqlite \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig:/opt/libxml2/lib/pkgconfig:/opt/libxslt/lib/pkgconfig" \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        /opt/qt5/bin/qmake -r \
            CMAKE_CONFIG+=ENABLE_TEST_SUPPORT=OFF \
            CMAKE_CONFIG+=ENABLE_API_TESTS=OFF \
            CMAKE_CONFIG+=USE_GSTREAMER=OFF \
            CMAKE_CONFIG+=USE_LIBHYPHEN=OFF \
            CMAKE_CONFIG+=USE_MEDIA_FOUNDATION=OFF \
            CMAKE_CONFIG+=USE_QT_MULTIMEDIA=ON \
            CMAKE_CONFIG+=USE_LD_GOLD=OFF \
            CMAKE_CONFIG+=ENABLE_WEBKIT2=OFF \
            CMAKE_CONFIG+=ENABLE_GEOLOCATION=OFF \
            CMAKE_CONFIG+=ENABLE_DEVICE_ORIENTATION=OFF \
            CMAKE_CONFIG+=CMAKE_CXX_FLAGS=-stdlib=libc++ \
            CMAKE_CONFIG+=CMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld \
            CMAKE_CONFIG+=CMAKE_MODULE_LINKER_FLAGS=-fuse-ld=lld \
            CMAKE_CONFIG+=CMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld \
            ../WebKit.pro && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    strip --strip-all /opt/qt5/lib/libQt5WebKit.so.$(echo ${QT_WEBKIT_VERSION} | sed 's|-.*||') && \
    strip --strip-all /opt/qt5/lib/libQt5WebKitWidgets.so.$(echo ${QT_WEBKIT_VERSION} | sed 's|-.*||') && \
    cd ../../.. && \
    rm -rf qtbase_old-compose-input-context_v${QT_XKB_COMPOSE_PATCH_VERSION}.patch qt-everywhere-opensource-src-${QT_VERSION}.tar.xz qtwebkit-${QT_WEBKIT_VERSION}.tar.xz qt-everywhere-src-${QT_VERSION}

RUN export QTSTYLEPLUGINS_COMMIT="335dbece103e2cbf6c7cf819ab6672c2956b17b3" && \
    wget --no-check-certificate https://gist.githubusercontent.com/AlienCowEatCake/44f259b25590a6ac7e40630b4779fb0a/raw/fix-build-qt5.15.patch && \
    wget --no-check-certificate https://github.com/qt/qtstyleplugins/archive/${QTSTYLEPLUGINS_COMMIT}.tar.gz && \
    tar -xvpf ${QTSTYLEPLUGINS_COMMIT}.tar.gz && \
    cd qtstyleplugins-${QTSTYLEPLUGINS_COMMIT} && \
    patch -p1 -i ../fix-build-qt5.15.patch && \
    mkdir build && \
    cd build && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        /opt/qt5/bin/qmake -r ../qtstyleplugins.pro && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd ../.. && \
    rm -rf fix-build-qt5.15.patch ${QTSTYLEPLUGINS_COMMIT}.tar.gz qtstyleplugins-${QTSTYLEPLUGINS_COMMIT}

RUN export QT5CT_VERSION="1.8" && \
    wget --no-check-certificate https://downloads.sourceforge.net/project/qt5ct/qt5ct-${QT5CT_VERSION}.tar.bz2 && \
    tar -xvpf qt5ct-${QT5CT_VERSION}.tar.bz2 && \
    cd qt5ct-${QT5CT_VERSION} && \
    mkdir build && \
    cd build && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        /opt/qt5/bin/qmake -r ../qt5ct.pro && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make install && \
    cd ../.. && \
    rm -rf qt5ct-${QT5CT_VERSION}.tar.bz2 qt5ct-${QT5CT_VERSION}

# @todo Build AppImageKit from source?
RUN export APPIMAGEKIT_VERSION="13" && \
    export P7ZIP_VERSION="16.02" && \
    echo "|i686|x86_64|arm|aarch64|" | grep -v "|$(gcc -dumpmachine | sed 's|-.*||')|" >/dev/null || ( \
    wget --no-check-certificate https://sourceforge.net/projects/p7zip/files/p7zip/${P7ZIP_VERSION}/p7zip_${P7ZIP_VERSION}_src_all.tar.bz2/download -O p7zip_${P7ZIP_VERSION}_src_all.tar.bz2 && \
    tar -xvpf p7zip_${P7ZIP_VERSION}_src_all.tar.bz2 && \
    cd p7zip_${P7ZIP_VERSION} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) 7z && \
    cd .. && \
    wget --no-check-certificate https://github.com/AppImage/AppImageKit/releases/download/${APPIMAGEKIT_VERSION}/appimagetool-$(gcc -dumpmachine | sed 's|-.*||' | sed 's|^arm$|armhf|').AppImage -O appimagetool-$(gcc -dumpmachine | sed 's|-.*||' | sed 's|^arm$|armhf|').AppImage && \
    mkdir squashfs-root && \
    cd squashfs-root && \
    ../p7zip_${P7ZIP_VERSION}/bin/7z x ../appimagetool-$(gcc -dumpmachine | sed 's|-.*||' | sed 's|^arm$|armhf|').AppImage && \
    cd .. && \
    rm -rf appimagetool-$(gcc -dumpmachine | sed 's|-.*||' | sed 's|^arm$|armhf|').AppImage p7zip_${P7ZIP_VERSION}_src_all.tar.bz2 p7zip_${P7ZIP_VERSION} && \
    mv squashfs-root /opt/appimagetool && \
    chmod -R 755 /opt/appimagetool && \
    ln -s /opt/appimagetool/AppRun /usr/local/bin/appimagetool )

RUN export LINUXDEPLOYQT_COMMIT="b00a83d99abecf3ab70fbff6d5aad48ec3791be2" && \
    git -c http.sslVerify=false clone https://github.com/probonopd/linuxdeployqt.git linuxdeployqt && \
    cd linuxdeployqt && \
    git checkout -f ${LINUXDEPLOYQT_COMMIT} && \
    git clean -dfx && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake -S . -B build \
            -G "Ninja" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_PREFIX_PATH=/opt/qt5 \
            -DCMAKE_C_COMPILER="/opt/clang/bin/clang" \
            -DCMAKE_CXX_COMPILER="/opt/clang/bin/clang++" \
            -DCMAKE_CXX_FLAGS=-stdlib=libc++ \
            -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld \
            -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=lld \
            -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld \
            -DGIT_COMMIT=${LINUXDEPLOYQT_COMMIT} \
            -DGIT_TAG_NAME=${LINUXDEPLOYQT_COMMIT} && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        cmake --build build --target all && \
    strip --strip-all build/tools/linuxdeployqt/linuxdeployqt && \
    cp -a build/tools/linuxdeployqt/linuxdeployqt /usr/local/bin/ && \
    cd .. && \
    rm -rf linuxdeployqt

RUN export PATCHELF_VERSION="0.18.0" && \
    wget --no-check-certificate https://github.com/NixOS/patchelf/releases/download/${PATCHELF_VERSION}/patchelf-${PATCHELF_VERSION}.tar.bz2 && \
    tar -xvpf patchelf-${PATCHELF_VERSION}.tar.bz2 && \
    cd patchelf-${PATCHELF_VERSION} && \
    CC="/opt/clang/bin/clang" \
    CXX="/opt/clang/bin/clang++" \
    CPP="/opt/clang/bin/clang++ -E" \
    CPPFLAGS="-stdlib=libc++" \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-static -stdlib=libc++ -lc++ -lc++abi -pthread -fuse-ld=lld" \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        ./configure --prefix=/usr/local && \
    setarch "$(gcc -dumpmachine | sed 's|-.*|| ; s|^arm$|linux32| ; s|^aarch64$|linux64| ; s|^powerpc64le$|linux64|')" \
        make -j$(getconf _NPROCESSORS_ONLN) && \
    strip --strip-all src/patchelf && \
    cp -a src/patchelf /usr/local/bin/ && \
    cd .. && \
    rm -rf patchelf-${PATCHELF_VERSION}.tar.bz2 patchelf-${PATCHELF_VERSION}
