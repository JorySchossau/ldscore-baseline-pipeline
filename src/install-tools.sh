function message {
    echo "tools/bin/$1 not found"
    echo "downloading..."
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

function main {
    $SHELL src/should-be-in-path.sh wget
    $SHELL src/should-be-in-path.sh tar
    $SHELL src/should-be-in-path.sh make
    $SHELL src/should-be-in-path.sh git

    axel_installed=$($SHELL src/is_tool_installed.sh axel)
    bcftools_installed=$($SHELL src/is_tool_installed.sh bcftools)
    bedtools_installed=$($SHELL src/is_tool_installed.sh bedtools)
    plink_installed=$($SHELL src/is_tool_installed.sh plink)
    # moreutils (check 'sponge')
    moreutils_installed=$($SHELL src/is_tool_installed.sh sponge)
    liftover_installed=$($SHELL src/is_tool_installed.sh liftOver)

    if [ $axel_installed == false ]; then
        message "axel"
        $SHELL src/install-axel.sh
    fi
    if [ $bcftools_installed == false ]; then
        message "bcftools"
        $SHELL src/install-bcftools.sh
    fi
    if [ $bedtools_installed == false ]; then
        message "bedtools"
        $SHELL src/install-bedtools.sh
    fi
    if [ $plink_installed == false ]; then
        message "plink"
        $SHELL src/install-plink.sh
    fi
    if [ $moreutils_installed == false ]; then
        message "moreutils"
        $SHELL src/install-moreutils.sh
    fi
    if [ $liftover_installed == false ]; then
        message "liftOver"
        $SHELL src/require-liftover.sh
    fi
    if ! [ -f tools/ldsc/ldsc.py ]; then
        $SHELL src/install-ldsc.sh
    fi
    bash src/add-path.sh
    export PATH=$PATH:$PWD/tools/bin
    echo "All tools should be installed now."
    require axel
    require bcftools
    require bedtools
    require plink
    require liftOver
    require git
    require sponge
    require python2
}

main
