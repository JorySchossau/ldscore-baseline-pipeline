# this script relies on step 2 (s2) files
# to produce frequency files.
# the formatting can be quite off so
# we custom format the whitespacing again
# to be tab delimited.

function check_for_s2() {
  # in: none
  # out: none
  # throws an error if stage 2 vcf
  if ! ls s2/*.gz 1> /dev/null 2>&1; then
    >&2 echo "Error: Stage 4 VCF-to-plink requires vcf gz files from Stage 2 subsetting, but no *.gz files found in s2 dir."
    exit 1
  fi
}

function convert_vcf_to_frq() {
  # in:
  #  $1 force:bool whether to overwrite current files
  # out: none
  force=$1
  mkdir -p s4
  for chrn in $(seq 1 22); do
    if [ -z $force ]; then
      if [ -f s4/subset.${chrn}.frq ]; then
        echo "s4/subset.${chrn}.frq already exists - skipping. (pass -f to force)"
        continue
      fi
    fi
    $SHELL src/should-be-in-path.sh sponge
    ## TODO could multithread this call using some plink option:
    plink --freq --vcf s2/subset.${chrn}.vcf.gz --vcf-half-call m --out s4/subset.${chrn}
    # fix any awkward whitespacing (--output-delimiter should be a TAB)
    tr -s ' ' <s4/subset.${chrn}.frq | cut -d' ' --output-delimiter='	' -f2-7 | sponge s4/subset.${chrn}.frq
    #note: the 'half-call m' option treats variant half-calls as missing
  done
  echo "found $(grep 'NA' -c <(cat s4/*.frq)) NA values in frq files"
  echo "converting NA to 0.0"
  sed -i 's/NA/0.0/g' s4/*.frq
}

function main() {
  echo "Beginning Stage 4 (VCF to frq)"
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
  check_for_s2
  convert_vcf_to_frq $force
}

main $*
