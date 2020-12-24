FROM ubuntu:14.04

RUN groupadd --gid 1000 user && \
    useradd --shell /bin/bash --home-dir /home/user --uid 1000 --gid 1000 --create-home user

RUN sed -i 's/^deb \(.*\)$/deb \1\ndeb-src \1\n/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y wget nano build-essential devscripts gcc g++ xserver-xorg-core fontconfig libgl1-mesa-dev fuse libxrender1 libxkbcommon-x11-0 libegl1-mesa && \
    apt-get build-dep -y dbus libpng freetype && \
    apt-get install -y cmake && \
    apt-get install -y libxkbcommon-dev libgtk-3-dev libfontconfig1-dev libfreetype6-dev libdbus-1-dev libcups2-dev libpulse-dev libasound2-dev libgtk2.0-dev && \
    apt-get clean

WORKDIR /usr/src

RUN wget https://releases.llvm.org/9.0.0/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz && \
    tar -xvpf clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz && \
    mv clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04 /opt/ && \
    rm -rf clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz

ENV PATH="/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin:${PATH}"

RUN wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz && \
    tar -xvpf openssl-1.1.1d.tar.gz && \
    cd openssl-1.1.1d && \
    setarch x86_64 ./Configure linux-x86_64 -m64 --prefix=/opt/qt-5.12.6_clang --openssldir=/etc/ssl zlib no-shared && \
    make depend && \
    make && \
    make install && \
    cd .. && \
    rm -rf openssl-1.1.1d.tar.gz openssl-1.1.1d

RUN wget https://github.com/qt/qtbase/commit/97ac281c1d70dcfbb137e5a83e24a747e9510116.patch -O qtbase_QTBUG-78238.patch && \
    wget https://download.qt.io/archive/qt/5.12/5.12.6/single/qt-everywhere-src-5.12.6.tar.xz && \
    tar -xvpf qt-everywhere-src-5.12.6.tar.xz && \
    cd qt-everywhere-src-5.12.6/qtbase && \
    patch -p1 -i ../../qtbase_QTBUG-78238.patch && \
    cd .. && \
    mkdir build && \
    cd build && \
    ../configure -prefix /opt/qt-5.12.6_clang -platform linux-clang -opensource -confirm-license -release -strip -c++std c++14 -no-use-gold-linker \
      -gui -widgets -dbus-linked -accessibility -glib -no-icu -qt-pcre -system-zlib -ssl -openssl-linked -no-libproxy \
      -fontconfig -system-freetype -qt-harfbuzz -gtk -opengl desktop -no-opengles3 -no-egl -qpa xcb -xcb-xlib \
      -no-directfb -no-eglfs -no-gbm -no-kms -no-linuxfb -no-mirclient -qt-xcb -no-libudev -no-evdev \
      -no-libinput -no-mtdev -no-tslib -xcb-xinput -xkbcommon -gif -ico -qt-libpng -qt-libjpeg \
      -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite2 \
      -sql-sqlite -no-sql-tds -qt-sqlite -qt-tiff -qt-webp -pulseaudio -alsa -no-gstreamer \
      -no-compile-examples -nomake examples -nomake tests -skip qt3d -skip qtactiveqt \
      -skip qtandroidextras -skip qtcanvas3d -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
      -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
      -skip qtmacextras -skip qtnetworkauth -skip qtpurchasing -skip qtquickcontrols \
      -skip qtquickcontrols2 -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors \
      -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtvirtualkeyboard \
      -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin -skip qtwebsockets \
      -skip qtwebview -skip qtwinextras -skip qtxmlpatterns -no-feature-qdoc \
      OPENSSL_PREFIX=/opt/qt-5.12.6_clang OPENSSL_LIBS='-lssl -lcrypto -lz -ldl -pthread' \
      QMAKE_CC=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
      QMAKE_CXX=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ \
      QMAKE_LINK_C=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
      QMAKE_LINK_C_SHLIB=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang \
      QMAKE_LINK=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ \
      QMAKE_LINK_SHLIB=/opt/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-14.04/bin/clang++ && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf qtbase_QTBUG-78238.patch qt-everywhere-src-5.12.6.tar.xz qt-everywhere-src-5.12.6

RUN wget https://github.com/qt/qtstyleplugins/archive/master.tar.gz -O qtstyleplugins-master.tar.gz && \
    tar -xvpf qtstyleplugins-master.tar.gz && \
    cd qtstyleplugins-master && \
    mkdir build && \
    cd build && \
    /opt/qt-5.12.6_clang/bin/qmake -r ../qtstyleplugins.pro && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf qtstyleplugins-master.tar.gz qtstyleplugins-master

RUN wget https://downloads.sourceforge.net/project/qt5ct/qt5ct-0.41.tar.bz2 && \
    tar -xvpf qt5ct-0.41.tar.bz2 && \
    cd qt5ct-0.41 && \
    mkdir build && \
    cd build && \
    /opt/qt-5.12.6_clang/bin/qmake -r ../qt5ct.pro && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf qt5ct-0.41.tar.bz2 qt5ct-0.41

RUN wget https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage -O appimagetool-x86_64.AppImage && \
    chmod +x appimagetool-x86_64.AppImage && \
    ./appimagetool-x86_64.AppImage --appimage-extract && \
    rm appimagetool-x86_64.AppImage && \
    mv squashfs-root /opt/appimagetool-x86_64.AppDir && \
    find /opt/appimagetool-x86_64.AppDir -type d -exec chmod 755 \{\} \; && \
    find /opt/appimagetool-x86_64.AppDir -type f -exec chmod +r \{\} \; && \
    find /opt/appimagetool-x86_64.AppDir -executable -type f -exec chmod +x \{\} \; && \
    ln -s /opt/appimagetool-x86_64.AppDir/AppRun /opt/appimagetool-x86_64.AppImage

RUN wget https://github.com/probonopd/linuxdeployqt/releases/download/6/linuxdeployqt-6-x86_64.AppImage -O linuxdeployqt-6-x86_64.AppImage && \
    chmod +x linuxdeployqt-6-x86_64.AppImage && \
    ./linuxdeployqt-6-x86_64.AppImage --appimage-extract && \
    rm linuxdeployqt-6-x86_64.AppImage && \
    mv squashfs-root /opt/linuxdeployqt-6-x86_64.AppDir && \
    find /opt/linuxdeployqt-6-x86_64.AppDir -type d -exec chmod 755 \{\} \; && \
    find /opt/linuxdeployqt-6-x86_64.AppDir -type f -exec chmod +r \{\} \; && \
    find /opt/linuxdeployqt-6-x86_64.AppDir -executable -type f -exec chmod +x \{\} \; && \
    ln -s /opt/linuxdeployqt-6-x86_64.AppDir/AppRun /opt/linuxdeployqt-6-x86_64.AppImage
