FROM ubuntu:14.04

RUN groupadd --gid 1000 user && \
    useradd --shell /bin/bash --home-dir /home/user --uid 1000 --gid 1000 --create-home user

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget build-essential fakeroot debhelper libgl1-mesa-dev libx11-xcb-dev && \
    apt-get install -y --no-install-recommends libxkbcommon-dev libgtk-3-dev libfontconfig1-dev libfreetype6-dev libdbus-1-dev libcups2-dev libpulse-dev libasound2-dev libgtk2.0-dev libxkbcommon-x11-dev && \
    apt-get install -y --no-install-recommends gperf bison ruby flex && \
    apt-get clean

WORKDIR /usr/src

RUN wget --no-check-certificate https://releases.llvm.org/9.0.0/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz && \
    tar -xvpf clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz && \
    mv clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04 /opt/ && \
    rm -rf clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz

ENV PATH="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/lib:/opt/qt-5.15.5_clang/lib"

RUN wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1q.tar.gz && \
    tar -xvpf openssl-1.1.1q.tar.gz && \
    cd openssl-1.1.1q && \
    setarch x86_64 ./Configure linux-x86_64 -m64 --prefix=/opt/qt-5.15.5_clang --openssldir=/etc/ssl zlib no-shared && \
    make depend && \
    make -j8 && \
    make install && \
    cd .. && \
    rm -rf openssl-1.1.1q.tar.gz openssl-1.1.1q

RUN wget --no-check-certificate https://github.com/unicode-org/icu/releases/download/release-67-1/icu4c-67_1-src.tgz && \
    tar -xvpf icu4c-67_1-src.tgz && \
    cd icu/source && \
    CC="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang" \
    CXX="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++" \
    CPP="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ -E" \
    CFLAGS="-fPIC" \
    CPPFLAGS="-stdlib=libc++ -fPIC" \
    CXXFLAGS="-stdlib=libc++ -fPIC" \
    LDFLAGS="-stdlib=libc++ -lc++ -lc++abi -fPIC" \
    ./configure --prefix=/opt/icu --disable-shared --enable-static --disable-tests --disable-samples --with-data-packaging=static && \
    make -j8 && \
    make install && \
    cd ../.. && \
    rm -rf icu icu4c-67_1-src.tgz

RUN wget --no-check-certificate https://download.gnome.org/sources/libxml2/2.9/libxml2-2.9.14.tar.xz && \
    tar -xvpf libxml2-2.9.14.tar.xz && \
    cd libxml2-2.9.14 && \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig" \
    CC="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang" \
    CXX="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++" \
    CPP="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ -E" \
    CPPFLAGS="-I/opt/icu/include -stdlib=libc++" \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-L/opt/icu/lib -stdlib=libc++ -lc++ -lc++abi" \
    ./configure --prefix=/opt/libxml2 --disable-shared --enable-static --with-pic --without-debug --without-docbook --without-python --without-iconv --with-icu && \
    make -j8 && \
    make install && \
    cd .. && \
    rm -rf libxml2-2.9.14 libxml2-2.9.14.tar.xz

RUN wget --no-check-certificate https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.35.tar.xz && \
    tar -xvpf libxslt-1.1.35.tar.xz && \
    cd libxslt-1.1.35 && \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig:/opt/libxml2/lib/pkgconfig" \
    CC="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang" \
    CXX="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++" \
    CPP="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ -E" \
    CPPFLAGS="-I/opt/icu/include -I/opt/libxml2/include -stdlib=libc++" \
    CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-L/opt/icu/lib -L/opt/libxml2/lib -stdlib=libc++ -lc++ -lc++abi" \
    ./configure --prefix=/opt/libxslt --disable-shared --enable-static --with-pic --without-python --without-debug --without-debugger --without-profiler && \
    make -j8 && \
    make install && \
    cd .. && \
    rm -rf libxslt-1.1.35.tar.xz libxslt-1.1.35

RUN wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v3.24.0/cmake-3.24.0-linux-x86_64.tar.gz && \
    tar -xvpf cmake-3.24.0-linux-x86_64.tar.gz && \
    mv cmake-3.24.0-linux-x86_64 /opt/ && \
    ln -s /opt/cmake-3.24.0-linux-x86_64/bin/cmake /usr/local/bin/ && \
    ln -s /opt/cmake-3.24.0-linux-x86_64/bin/ctest /usr/local/bin/ && \
    ln -s /opt/cmake-3.24.0-linux-x86_64/bin/ccmake /usr/local/bin/ && \
    ln -s /opt/cmake-3.24.0-linux-x86_64/bin/cpack /usr/local/bin/ && \
    rm -rf cmake-3.24.0-linux-x86_64.tar.gz

RUN wget --no-check-certificate https://mirror.yandex.ru/mirrors/qt.io/archive/qt/5.14/5.14.2/submodules/qtbase-everywhere-src-5.14.2.tar.xz && \
    tar -xvpf qtbase-everywhere-src-5.14.2.tar.xz && \
    cd qtbase-everywhere-src-5.14.2/src/3rdparty/xcb && \
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
    rm -rf qtbase-everywhere-src-5.14.2.tar.xz qtbase-everywhere-src-5.14.2

RUN wget --no-check-certificate https://github.com/AlienCowEatCake/qtbase/compare/v5.15.0...feature/old-compose-input-context_v5.15.0.diff -O qtbase_old-compose-input-context_v5.15.0.patch && \
    wget --no-check-certificate https://mirror.yandex.ru/mirrors/qt.io/archive/qt/5.15/5.15.5/single/qt-everywhere-opensource-src-5.15.5.tar.xz && \
    wget --no-check-certificate https://github.com/qtwebkit/qtwebkit/releases/download/qtwebkit-5.212.0-alpha4/qtwebkit-5.212.0-alpha4.tar.xz && \
    tar -xvpf qt-everywhere-opensource-src-5.15.5.tar.xz && \
    cd qt-everywhere-src-5.15.5/qtbase && \
    patch -p1 -i ../../qtbase_old-compose-input-context_v5.15.0.patch && \
    cd .. && \
    mkdir build && \
    cd build && \
    ../configure -prefix /opt/qt-5.15.5_clang -platform linux-clang-libc++ -opensource -confirm-license -release -strip -c++std c++2a -linker lld \
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
        OPENSSL_PREFIX=/opt/qt-5.15.5_clang OPENSSL_LIBS='-lssl -lcrypto -lz -ldl -pthread' \
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
        QMAKE_CC=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
        QMAKE_CXX=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ \
        QMAKE_LINK_C=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
        QMAKE_LINK_C_SHLIB=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
        QMAKE_LINK=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ \
        QMAKE_LINK_SHLIB=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ && \
    make -j8 && \
    make install && \
    cd .. && \
    tar -xvpf ../qtwebkit-5.212.0-alpha4.tar.xz && \
    cd qtwebkit-5.212.0-alpha4 && \
    echo 'set(ICU_LIBRARIES "/opt/icu/lib/libicui18n.a;/opt/icu/lib/libicuuc.a;/opt/icu/lib/libicudata.a")' >> Source/cmake/FindICU.cmake && \
    echo 'set(ICU_I18N_LIBRARIES "/opt/icu/lib/libicui18n.a;/opt/icu/lib/libicuuc.a;/opt/icu/lib/libicudata.a")' >> Source/cmake/FindICU.cmake && \
    mkdir build && \
    cd build && \
    SQLITE3SRCDIR=${PWD}/../../qtbase/src/3rdparty/sqlite \
    PKG_CONFIG_PATH="/opt/icu/lib/pkgconfig:/opt/libxml2/lib/pkgconfig:/opt/libxslt/lib/pkgconfig" \
    /opt/qt-5.15.5_clang/bin/qmake -r \
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
        ../WebKit.pro && \
    make -j8 && \
    make install && \
    strip --strip-all /opt/qt-5.15.5_clang/lib/libQt5WebKit.so.5.212.0 && \
    strip --strip-all /opt/qt-5.15.5_clang/lib/libQt5WebKitWidgets.so.5.212.0 && \
    cd ../../.. && \
    rm -rf qtbase_old-compose-input-context_v5.15.0.patch qt-everywhere-opensource-src-5.15.5.tar.xz qtwebkit-5.212.0-alpha4.tar.xz qt-everywhere-src-5.15.5

RUN wget --no-check-certificate https://gist.githubusercontent.com/AlienCowEatCake/44f259b25590a6ac7e40630b4779fb0a/raw/fix-build-qt5.15.patch && \
    wget --no-check-certificate https://github.com/qt/qtstyleplugins/archive/master.tar.gz -O qtstyleplugins-master.tar.gz && \
    tar -xvpf qtstyleplugins-master.tar.gz && \
    cd qtstyleplugins-master && \
    patch -p1 -i ../fix-build-qt5.15.patch && \
    mkdir build && \
    cd build && \
    /opt/qt-5.15.5_clang/bin/qmake -r ../qtstyleplugins.pro && \
    make -j8 && \
    make install && \
    cd ../.. && \
    rm -rf fix-build-qt5.15.patch qtstyleplugins-master.tar.gz qtstyleplugins-master

RUN wget --no-check-certificate https://downloads.sourceforge.net/project/qt5ct/qt5ct-1.5.tar.bz2 && \
    tar -xvpf qt5ct-1.5.tar.bz2 && \
    cd qt5ct-1.5 && \
    mkdir build && \
    cd build && \
    /opt/qt-5.15.5_clang/bin/qmake -r ../qt5ct.pro && \
    make -j8 && \
    make install && \
    cd ../.. && \
    rm -rf qt5ct-1.5.tar.bz2 qt5ct-1.5

RUN wget --no-check-certificate https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O appimagetool-x86_64.AppImage && \
    chmod +x appimagetool-x86_64.AppImage && \
    ./appimagetool-x86_64.AppImage --appimage-extract && \
    rm appimagetool-x86_64.AppImage && \
    mv squashfs-root /opt/appimagetool-x86_64.AppDir && \
    find /opt/appimagetool-x86_64.AppDir -type d -exec chmod 755 \{\} \; && \
    find /opt/appimagetool-x86_64.AppDir -type f -exec chmod +r \{\} \; && \
    find /opt/appimagetool-x86_64.AppDir -executable -type f -exec chmod +x \{\} \; && \
    ln -s /opt/appimagetool-x86_64.AppDir/AppRun /opt/appimagetool-x86_64.AppImage

RUN wget --no-check-certificate https://github.com/probonopd/linuxdeployqt/releases/download/7/linuxdeployqt-7-x86_64.AppImage -O linuxdeployqt-7-x86_64.AppImage && \
    chmod +x linuxdeployqt-7-x86_64.AppImage && \
    ./linuxdeployqt-7-x86_64.AppImage --appimage-extract && \
    rm linuxdeployqt-7-x86_64.AppImage && \
    mv squashfs-root /opt/linuxdeployqt-7-x86_64.AppDir && \
    find /opt/linuxdeployqt-7-x86_64.AppDir -type d -exec chmod 755 \{\} \; && \
    find /opt/linuxdeployqt-7-x86_64.AppDir -type f -exec chmod +r \{\} \; && \
    find /opt/linuxdeployqt-7-x86_64.AppDir -executable -type f -exec chmod +x \{\} \; && \
    ln -s /opt/linuxdeployqt-7-x86_64.AppDir/AppRun /opt/linuxdeployqt-7-x86_64.AppImage
