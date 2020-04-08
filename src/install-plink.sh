mkdir -p tools/src
mkdir -p tools/bin

# obtained from:
# https://www.cog-genomics.org/plink2

# URLs for obtaining plink.
# update these / check them if they ever change.
server="http://s3.amazonaws.com/plink1-assets"
linux_filename="plink_linux_x86_64_latest.zip"
mac_filename="plink_mac_20190617.zip"

# determine if mac or linux and download the correct one.
OS=$($SHELL src/get-os-name.sh)
case "$OS" in
  *linux*)
    wget -L "${server}/${linux_filename}" -O tools/src/${linux_filename}
    cd tools/src
    unzip ${linux_filename} -d plink
    ;;
  *mac*)
    wget -L "${server}/${mac_filename}" -O tools/src/${mac_filename}
    cd tools/src
    unzip ${mac_filename} -d plink
    ;;
  *)
    >&2 echo "Error: OS '$OS' not supported, or you're using windows."
    >&2 echo "Download manually and place the plink executable in tools/bin and try again."
    exit 1
  ;;
esac

cd plink
cp plink ../../bin/
cp prettify ../../bin/

# now exists: ../../bin
