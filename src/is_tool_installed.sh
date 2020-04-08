function is_tool_installed() {
  # in: string of executable name
  # out: true or false
  tool=$1
  if $(command -v $tool &>/dev/null); then
    echo "true"
  else
    echo "false"
  fi
}

function require() {
  # in:
  #   $1 string name of required executable
  #   $2 true or false (previously determined if we have this exec)
  # out: none, throws error if required and we don't have it available yet
  name=$1
  has_tool=$2
  if ! $has_tool; then
    >&2 echo "Error: $name is required, but it doesn't seem to be installed."
    exit 1
  fi
}

toolname=$1
isinstalled=$(is_tool_installed $toolname)
#require $toolname $isinstalled
echo $isinstalled
