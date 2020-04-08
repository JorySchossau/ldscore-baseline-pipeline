# This script install axel from source
# If on MAC, it assumes you've used homebrew to install pkg-config and openssl (brew install pkg-config openssl)

mkdir -p tools/src
mkdir -p tools/bin

cd tools/src

# obtained from:
# https://github.com/axel-download-accelerator/axel/releases
if ! [ -f axel-2.17.3.tar.gz ]; then
wget -L "https://github.com/axel-download-accelerator/axel/releases/download/v2.17.3/axel-2.17.3.tar.gz"
fi

tar -xvzf axel-2.17.3.tar.gz

cd axel-2.17.3

OS=$($SHELL src/get-os-name.sh)
if [ "$OS" == "mac" ]; then
    echo "setting appropriate compiler flags for mac environment."
    export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
    ./configure --prefix=$PWD/../../ LDFLAGS="-L/usr/local/opt/openssl/lib" CPPFLAGS="-I/usr/local/opt/openssl/include"
else
    ./configure --prefix=$PWD/../../
fi

make -j2

make install

# now exists: tools/bin
