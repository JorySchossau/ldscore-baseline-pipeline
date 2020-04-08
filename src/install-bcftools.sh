# This script downloads and installs bcftools. Works on Mac, too.

mkdir -p tools/src
mkdir -p tools/bin

cd tools/src

# obtained from:
# http://www.htslib.org/download/
if ! [ -f bcftools-1.9.tar.bz2 ]; then
    wget -L "https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2"
fi

tar -xvjf bcftools-1.9.tar.bz2

cd bcftools-1.9

./configure --prefix=$PWD/../../

make -j2

make install

# now exists: tools/bin
