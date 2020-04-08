## detect mac or linux
OS="none"
uname_result=$(uname -s)
uname_result=$(echo $uname_result | tr '[:upper:]' '[:lower:]')
case "$uname_result" in
  *linux*)
    OS="linux"
  ;;
  *bsd*)
    OS="linux"
  ;;
  *darwin*)
    OS="mac"
  ;;
  *mingw*)
    OS="win"
  ;;
  *cygwin*)
    OS="win"
  ;;
  *)
    OS="none"
  ;;
esac
echo $OS
