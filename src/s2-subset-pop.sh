# this script is interactive
# it walks you through subsetting the 1000 genomes data
# downloaded from step 1 (s1).

function check_for_s1_and_panel() {
  # in: none
  # out: none
  # throws an error if stage 1 vcf or
  # stage 1 panel files are not present
  if [ ! -f s1/1kg/samples.panel ]; then
    >&2 echo "Error: Stage 2 subsetting requires a samples panel file for the meta population. Did you do Stage 1?"
    exit 1
  fi
  if ! ls s1/1kg/*.gz 1> /dev/null 2>&1; then
    >&2 echo "Error: Stage 2 subsetting requires vcf gz files from Stage 1."
    exit 1
  fi
}

function print_available_populations() {
  # in: none
  # out: none
  echo "Population (1st) and Super Population (2nd) Codes Available:"
  tail -n +2 s1/1kg/samples.panel | cut -f2,3 | sort -k2 -k1 | uniq
  echo ""
}

function get_population_selection() {
  # in: none
  # out: string csv of 1k pop codes for subsetting
  # Ignores panle header, prints out pop and super pop codes
  # gets csv string from user of desired pop and/or super pop codes
  # guarantees upper case
  # assumes no spaces
  codes=""
  while [ -z "$codes" ]; do
    read -r -p "Specify a comma delimited list of population and/or super population codes, no spaces, case irrelevant"$'\n'"codes:" codes
    codes=$(echo $codes | tr '[:lower:]' '[:upper:]')
  done
  echo "$codes"
}

function create_subsetting_file() {
  # in: user csv string of pop codes (no spaces)
  # out: none
  # creates s2/pop_subsample that contains
  # 1 sample code (ex 'HO99375') per line
  # and is used to subset all the VCF files
  # from stage 1.
  mkdir -p s2
  selection=$1
  selection_grepclause=$(echo "$selection" | tr -s ',' '|')
  grep -E "$selection_grepclause" s1/1kg/samples.panel | cut -f1 > s2/pop_subsample
}

function subset_vcf_into_stage_2() {
  # in:
  #  $1 force:bool whether to overwrite current files
  # out: none
  # subsets all the vcf files from stage 1
  # into the stage 2 folder using the
  # codes supplied by the user,
  # now stored as sample IDs in s2/pop_subsample
  force=$1
  for chrn in {22..1}; do
    if [ -z $force ]; then
      if [ -f s2/subset.${chrn}.vcf.gz ]; then
        echo "s2/subset.${chrn}.vcf.gz already exists - skipping. (pass -f to force)"
        continue
      fi
    fi
    echo -ne "subsetting chr ${chrn}..."
    # exclude MAF < 0.05
    bcftools view -S s2/pop_subsample -e'MAF<0.05' -o s2/subset.${chrn}.vcf.gz -O z --threads 8 s1/1kg/ALL.chr${chrn}[!0-9]*.vcf.gz #TODO updated with [!0-9] wildcard exclusion
    echo " done"
  done
}

# functions available
# check_for_s1_and_panel()
# print_available_populations()
# get_population_selection():string
# create_subsetting_file(pop_codes)
# subset_vcf_into_stage_2()

function main() {
  echo "Beginning Stage 2 (subsetting VCF data)"
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
  check_for_s1_and_panel
  print_available_populations
  selection=$(get_population_selection)
  create_subsetting_file "$selection"
  subset_vcf_into_stage_2 $force
}

main $*

#tail -n +2 s1/1kg/samples.panel | cut -f2,3 | sort -k2 -k1 | uniq
#ACB AFR
#ASW AFR
#...
#CEU EUR
#FIN EUR
#
#read -r -p "comma delimited list of population and super population codes, mixing allowed, no spaces, case irrelevant"$'\n'"codes:" codes
#typeset -u codes=$codes
#grepclause=$(tr -s ',' '|')
#
#grep -E "GBR|SAS" s1/1kg/samples.panel | less
#grep -E "GBR|SAS" s1/1kg/samples.panel | cut -f1 > subsample
#
#grep -E "$grepclause" s1/1kg/samples.panel | cut -f1 > s1/pop_subsample.list
#
#mkdir s2
#
#bcftools view -S subsample -o newfile.vcf.gz -O z --threads 8 s1/1kg/ALL.chr22_GRCh38.genotypes.20170504.vcf.gz
