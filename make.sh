#!/bin/bash
# Download and Build QtCreator Doxygen plugin from source
set -e

# qtcbranch=v3.2.1
qtversion=5.3

qtsdk_install=~/Qt
qtcreator_install=$qtsdk_install/Tools/QtCreator

while getopts "sb:c:q:i:v:" optname; do
    case "$optname" in
        b) qtcbranch=$OPTARG ;;
        s) doDownload=1 ;;
        c) qtcreator_src=$OPTARG ;;
        q) qtsdk_install=$OPTARG ;;
        i) qtcreator_install=$OPTARG ;;
        v) qtversion=$OPTARG ;;
    esac
done

[[ $doDownload ]] || { cat README; exit 1; }

me=$PWD

[[ $qtcbranch ]] || {
# No version set, get current QtCreator version
    $qtcreator_install/bin/qtcreator.sh -version > version.txt 2>&1
    qtcreator_version_txt=`grep 'Qt Creator' version.txt | grep 'based on'`
    rm version.txt
    arr=($qtcreator_version_txt)
    qtcbranch="v${arr[2]}"
    qt_ver=${arr[6]}
    echo "Auto-detected: QtCreator $qtcbranch based on Qt $qt_ver"
    qtversion=${qt_ver:0:3}
}

export PATH="$qtsdk_install/$qtversion/gcc_64/bin/:$PATH"

[[ $qtcreator_src ]] || qtcreator_src=$me/qt-creator-src
[ ! -e $qtcreator_src ] && {
    git clone --single-branch --branch $qtcbranch --recursive https://git.gitorious.org/qt-creator/qt-creator.git $qtcreator_src
}

doxygen_src=$me/plugins/kofee/doxygen
doxygen_dest=$qtcreator_install/lib/qtcreator/plugins/Kofee
doxygen_build=$me/build/kofee/doxygen

[ ! -e $doxygen_src ] && {
    mkdir -p $doxygen_build
    mkdir -p $doxygen_dest

    git svn clone http://svn.kofee.org/svn/qtcreator-doxygen/trunk $doxygen_src
    wget http://dev.kofee.org/attachments/download/87/qtcreator-3.2.2.patch -P $doxygen_src
    
    cd $doxygen_src
    patch < qtcreator-3.2.2.patch

    echo 'INCLUDEPATH += $$QTC_SOURCE_DIR/src/libs/3rdparty' >> $doxygen_src/doxygen.pro
}

cd $doxygen_src
qmake QTC_SOURCE_DIR=$qtcreator_src \
QTC_BUILD_DIR=$doxygen_build \
LIBSROOT=$qtcreator_install/lib \
DEST=$doxygen_dest
make

cd $me

echo "All done"
