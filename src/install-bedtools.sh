# This script downloads and installs bedtools. Works on Mac, too.

mkdir -p tools/src
mkdir -p tools/bin

cd tools/src

# obtained from:
# https://github.com/arq5x/bedtools2/releases
if ! [ -f bedtools-2.28.0.tar.gz ]; then
    wget -L "https://github.com/arq5x/bedtools2/releases/download/v2.28.0/bedtools-2.28.0.tar.gz"
fi

tar -xvzf bedtools-2.28.0.tar.gz

cd bedtools2

# this is a backwards compatability fix for the newer gcc to target older binutils, in a sense.
sed -i 's/ -g/ -g1/g' Makefile src/utils/htslib/Makefile

make -j2

cp bin/* ../../bin

# now exists: tools/bin
