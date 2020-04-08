function main() {
  # in: name of utility
  # out: none
  # fails if utility is not in path
  # and tells user how to add the tools/bin etc. to their path
  toolname=$1
  if ! $(bash src/is_tool_installed.sh $toolname); then
    >&2 echo "Error: $toolname should be in your path now, but it's not."
    >&2 echo "Maybe you don't have it installed?"
    >&2 echo "If it's one of the bioinformatics tools downloaded here, then the following applies."
    echo "The following should be in your bash rc or profile:"
    echo "export PATH=$PWD/tools/bin:\$PATH"
    echo "export MANPATH$PWD/tools/share/man:\$MANPATH"
    echo
    $SHELL src/add-path.sh
  fi
}

main $*
