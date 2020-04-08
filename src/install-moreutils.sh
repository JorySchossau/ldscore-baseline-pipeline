# This script downloads and installs moreutils. Works on Mac, too.

mkdir -p tools/src
mkdir -p tools/bin

# obtained from:
# https://packages.debian.org/sid/moreutils
URL="http://deb.debian.org/debian/pool/main/m/moreutils/moreutils_0.63.orig.tar.xz" 

# convert filename to folder name
DIRNAME=$(basename $(echo $URL | tr '_' '-') .orig.tar.xz)

# download only if not already downloaded
if ! [ -f tools/src/moreutils.tar.xz ]; then
    wget -L "$URL" -O tools/src/moreutils.tar.xz
fi

tar -C tools/src -xvJf tools/src/moreutils.tar.xz
cd tools/src/$DIRNAME

# make everything but isutf8 because I get an error about a some docs file on my hpcc system
make -j2 ifdata ifne pee sponge mispipe lckdo parallel errno
mv ifdata ifne pee sponge mispipe lckdo parallel errno chronic combine vipe zrun ts vidir ../../bin
cd ../..

# now exists: tools/bin
