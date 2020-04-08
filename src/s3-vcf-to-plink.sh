# this script simply uses the files from step 2 (s2)
# and converts them to plink (bed/bim/fam) format linearly.
# With properly filtered vcfs this should be fairly fast.

function check_for_s2() {
  # in: none
  # out: none
  # throws an error if stage 2 vcf
  if ! ls s2/*.gz 1> /dev/null 2>&1; then
    >&2 echo "Error: Stage 3 VCF-to-plink requires vcf gz files from Stage 2 subsetting, but no *.gz files found in s2 dir."
    exit 1
  fi
}

function convert_vcf_to_plink() {
  # in:
  #  $1 force:bool whether to overwrite current files
  # out: none
  force=$1
  mkdir -p s3
  for chrn in $(seq 1 22); do
    if [ -z $force ]; then
      if [ -f s3/subset.${chrn}.bed ]; then
        echo "s3/subset.${chrn}.bed|bim|fam already exists - skipping. (pass -f to force)"
        continue
      fi
    fi
    plink --vcf s2/subset.${chrn}.vcf.gz --make-bed --freq --vcf-half-call m --out s3/subset.${chrn}
    #note: the 'half-call m' option treats variant half-calls as missing
  done
}

function main() {
  echo "Beginning Stage 3 (VCF to plink)"
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
  convert_vcf_to_plink $force
}

main $*
