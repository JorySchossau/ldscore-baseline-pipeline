# This just downloads the ldsc tool if necessary.
# This used to be a separate step,
# but I've since folded it into another step
# because it made more sense.

function is_present_ldsc() {
  # in: none
  # out: true, false
  # checks for existing ldsc folder in tools:
  # tools/ldsc/ldsc.py
  # and asks if you want to get it if
  # it hasn't been downloaded yet.
  # Errors out if you say no.
  if [ -f tools/ldsc/ldsc.py ]; then
    echo "true"
  else
    echo "false"
  fi
}

function download_ldsc() {
  # in: none
  # out: none
  # just downloads ldsc and checks to see if successful
  # check if git is installed
  rm -rf tools/ldsc >/dev/null
  if ! $($SHELL src/is_tool_installed.sh git); then
    >&2 echo "Error: No git seems to be present. Please install this and try again."
    exit 1
  fi
  # perform download
  git clone https://github.com/bulik/ldsc tools/ldsc
  # check if successful
  if ! $(is_present_ldsc); then
    >&2 echo "Error: Couldn't seem to download ldsc using git."
    >&2 echo "The repository is supposed to be here: https://github.com/bulik/ldsc"
    >&2 echo "Try manually downloading it to tools/ldsc and running this step again"
    exit 1
  fi
}

function check_should_download() {
  # in: force:bool
  # out: dodownload:bool
  # checks force flag and if not being forced
  # asks user if it should download ldsc
  # verifies presence of ldsc before/after
  # and presence of git before download
  force=$1
  userwantsdownload="n" # assume 'no'
  if [ -z $force ]; then
    if ! $(is_present_ldsc); then
      read -r -p  "It looks like you don't have the LDSC tool yet (in tools/ldsc)."$'\n'"Would you like to download it? [Y/n]:" userwantsdownload
      # to lowercase
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
      >&2 echo "Skipping download"
      ;;
  esac
  echo "$dodownload"
}

# functions available
# is_present_ldsc():bool
# download_ldsc()
# check_should_download(force:bool):bool

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
    download_ldsc
  elif ! $(is_present_ldsc); then
    >&2 echo "No LDSC tool present. Please resolve this before trying again"
    >&2 echo "The project url is: https://github.com/bulik/ldsc"
    exit 1
  fi
}

main $*
