OS=$($SHELL src/get-os-name.sh)
if [ "$OS" == "bsd" ]; then
    OS="mac" # good enough for purposes of realpath replacement
fi
if [ "$OS" == "mac" ]; then
    realpath() {
        [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
    }
    #export -f realpath
fi

function get_profile() {
  # in: none
  # out: returns path to preferable
  bash_profile="$HOME/.bash_profile"
  bashrc="$HOME/.bashrc"
  if [ -f $bash_profile ]; then
    echo $bash_profile
  elif [ -f $bashrc ]; then
    echo $bashrc
  else
    >&2 echo "Error: no .bashrc or .bash_profile in \$HOME"
    exit 1
  fi
}

function modify_path() {
  # in:
  #  $1 path to profile to modify
  #  $2 string data to add to profile
  # out: none
  profile=$1
  newlines=$2
  # check writable permission
  if [ ! -w $profile ]; then
    >&2 echo "Error: permissions problem. You don't have permission to write to $profile"
    exit 1
  fi
  # modify file
  echo "" >> $profile
  echo "$newlines" >> $profile
}

function is_string_in_path() {
  # in: string to check if it is in path ex: /.local/bin
  # out: true or false
  # tests if a subpath is in the path already
  tools_path=$1
  case "$PATH" in
    *$tools_path*)
      echo "true"
      ;;
    *)
      echo "false"
  esac
}

# functions available:
# get_profile()
# modify_path(profile_path, new_lines)
# is_string_in_path(a_path)

function main() {
  # this will test if the downloaded tools path is not already in your path
  # and it will add it to your bashrc or bash_profile if needed
  # it also checks if the profile file has been appended already,
  # but not yet activated and will tell you. It can't tell if those
  # lines have merely been commented out though and the suggestion
  # will be wrong if this is the case, but this is unlikely.
  tools_path=$(realpath $PWD/tools/bin)
  tools_man_path=$(realpath $PWD/tools/share/man)
  new_lines="export PATH=\$PATH:$tools_path"$'\n'"export MANPATH=\$MANPATH:$tools_man_path"
  # profile is .bashrc or .bash_profile or get_profile() throws error ()
  profile=$(get_profile)
  # check if path is already modified
  already_modified=$(is_string_in_path "$tools_path")
  if $(grep -Fq "$tools_path" $profile); then
    if ! $already_modified; then
      >&2 echo "Error: The tools path has previously been added to your $profile, but it isn't in your current session's PATH or it has been commented out"
      >&2 echo "Please reload your session or type 'source $profile' to use the new PATH environment"
      exit 1
    fi
  fi
  if $already_modified; then
    # all good, finish and return
    return
  fi
  echo "Tools installed to: $tools_path"
  do_modify_path=false
  # makes input -r (ignore previous bindings) -l (lowercase)
  read -r -p "Would you like to add the installed tools to your path? [Y/n]:" response
  response=$(echo $response | tr '[:upper:]' '[:lower:]')
  case "$response" in
    # true if user types ',BLANK,y,yes'
    # false if user types anything else
    [y])
      do_modify_path=true
      ;;
    "yes")
      do_modify_path=true
      ;;
    "")
      do_modify_path=true
      ;;
    *)
      echo "skipping path modification"
  esac
  if $do_modify_path; then
    echo "performing path modification"
    echo "Now please relaunch the session or source the modified profile to have access to the tools:"
    echo "ex: \$ source $profile"
    modify_path "$profile" "$new_lines"
  fi
}

main
