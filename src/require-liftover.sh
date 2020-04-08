
function is_present_liftOver() {
  # in: none
  # out: boolean
  # checks for liftOver in path
  if [ -f tools/bin/liftOver ]; then
    echo true
  else
    echo false
  fi
}

function verify_wget_tool_or_error() {
  # in: none
  # out: none
  # requires wget and throws error if not present
  if ! $(bash src/is_tool_installed.sh wget); then
    >&2 echo "Error: wget is needed for downloading. Please install it and try again."
    exit 1
  fi
}

function download_liftOver() {
  # in: none
  # out: none
  # requires wget
  # verifies no download error
  verify_wget_tool_or_error
  mkdir -p ../tools/bin
  OS=$($SHELL src/get-os-name.sh)
  if [ "$OS" == "none" ]; then
    >&2 echo "Error: I'm not sure what OS you're running '$uname_result' so I can't get the liftover tool."
    >&2 echo "Download it manually, place it in tools/bin and try again to verify."
    >&2 echo "File URL mac: http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver"
    >&2 echo "File URL linux: http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"
    exit 1
  fi
  if [ "$OS" == "win" ]; then
    >&2 echo "Error: the liftover tool required only runs on mac/linux/bsd, NOT windows."
    >&2 echo "Please run this again on a computer with one of those operating systems if you need liftover."
    exit 1
  fi
  # obtained from:
  # http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
  if [ "$OS" == "linux" ]; then
      wget -L "http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver" -O tools/bin/liftOver
  fi
  if [ $? -ne 0 ]; then
    >&2 echo "Error: download of liftOver failed using wget. Try manually, place it in tools/bin and try again to verify."
    >&2 echo "File URL mac: http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver"
    >&2 echo "File URL linux: http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"
    exit 1
  fi
  if [ "$OS" == "mac" ]; then
      wget -L "http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver" -O tools/bin/liftOver
  fi
  if [ $? -ne 0 ]; then
    >&2 echo "Error: download of liftOver failed using wget. Try manually, place it in tools/bin and try again to verify."
    >&2 echo "File URL mac: http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver"
    >&2 echo "File URL linux: http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"
    exit 1
  fi
  if ! [ -f tools/bin/liftOver ]; then
    >&2 echo "Error: couldn't write file for some reason. Try manually, place it in tools/bin and try again to verify."
    >&2 echo "File URL mac: http://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver"
    >&2 echo "File URL linux: http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"
    exit 1
  fi
  chmod +x tools/bin/liftOver
}

function check_should_download() {
  # in: force:bool
  # out: dodownload:bool
  # checks force flag and if not being forced
  # asks user if it should download liftOver
  # verifies presence of liftOver after
  force=$1
  userwantsdownload="n" # assume 'no'
  if [ -z $force ]; then
    if ! $(is_present_liftOver); then
      read -r -p  "It looks like you don't have the liftOver tool yet (in tools/bin)."$'\n'"Would you like to download it? [Y/n]:" userwantsdownload
      userwantsdownload=$(echo $userwantsdownload | tr '[:upper:]' '[:lower:]')
    fi
  else
    userwantsdownload="y"
  fi
  dodownload=false
  case "$userwantsdownload" in
    "")
      dodownload=true
      ;;
    "y")
      dodownload=true
      ;;
    "yes")
      dodownload=true
      ;;
    *)
      dodownload=false
      >&2 echo "Skipping liftOver download"
      ;;
  esac
  echo "$dodownload"
}

function check_and_download_chainfile() {
  # in: force:bool
  # out: dodownload:bool
  # checks force flag and if not being forced
  # asks user if it should download liftOver chainfile
  # verifies presence of file after
  force=$1
  userwantsdownload="n" # assume 'no'
  if [ -z $force ]; then
    if ! [ -f tools/bin/hg19ToHg38.over.chain.gz ]; then
      read -r -p  "It looks like you don't have the liftOver CHAINFILE yet (in tools/bin)."$'\n'"Would you like to download it? [Y/n]:" userwantsdownload
      userwantsdownload=$(echo ${userwantsdownload} | tr '[:upper:]' '[:lower:]')
    fi
  else
    userwantsdownload="y"
  fi
  dodownload=false
  case "$userwantsdownload" in
    "")
      dodownload=true
      ;;
    "y")
      dodownload=true
      ;;
    "yes")
      dodownload=true
      ;;
    *)
      dodownload=false
      >&2 echo "Skipping liftOver chainfile download"
      ;;
  esac
  if $dodownload; then
    $SHELL src/should-be-in-path.sh wget
    wget -L "http://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz" -O tools/bin/hg19ToHg38.over.chain.gz
    if ! [ -f tools/bin/hg19ToHg38.over.chain.gz ]; then
      >&2 echo "Error: Could not download or save chain file. Try manually and save it to tools/bin/"
      >&2 echo "Tried URL: http://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz"
      exit 1
    fi
  fi
}

# functions available
# check_liftOver_installed
# verify_wget_tool_or_error
# download_liftOver

function main() {
  force=$1
  case "$force" in
    "-f")
      force=true
      ;;
    "")
      ;;
    *)
      >&2 echo "Error: unknown flag '$force'"
      exit 1
  esac
  dodownload=$(check_should_download $force)
  if $dodownload; then
    download_liftOver
  elif ! $(is_present_liftOver); then
    >&2 echo "No liftOver tool present. Please resolve this and try again."
    >&2 echo "File URL mac: http://hgdownload.cse.ucsc.edu/admin/exe/MacOSX.x86_64/liftOver"
    >&2 echo "File URL linux: http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver"
    exit 1
  fi
  $SHELL src/should-be-in-path.sh liftOver
  check_and_download_chainfile $force
}

main $*

# now exists: ../../bin
