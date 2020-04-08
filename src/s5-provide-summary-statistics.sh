# This step either simply copies the sumstats file to the right place,
# preparing for munge_stats.py,
# or performs a liftover to make it hg38
# The user must specify the genome build of the sumstats file
# and we'll do the right thing prepping it for munge_stats.
# example: bash src/s5-provide-summary-statistics.sh pgc.scz2.fullsnps.gz hg38

function require_liftover() {
  $SHELL src/require-liftover.sh
}

function decompress_sumstats_if_needed() {
  # in:
  #  $1 sumstats filename (compressed)
  #  $2 force: bool
  # out: none
  # produces s5/${filename} without .gz extension
  sumstats_compressed=$1
  force=$2
  $SHELL src/should-be-in-path.sh basename
  sumstats=$(basename $sumstats_compressed .gz)
  dodecompression=true
  if ! $force; then
    if [ -f s5/$sumstats ]; then
      dodecompression=false
    fi
  fi
  if $dodecompression; then
    echo "Decompressing $sumstats_compressed"
    $SHELL src/should-be-in-path.sh gzip
    gzip -dc $sumstats_compressed > s5/$sumstats
  else
    echo "s5/$sumstats already decompressed, skipping decompression"
  fi
}

function error_if_not_all_bed_files() {
  NUM_FILES=$(ls -1 s3/subset.*.bim | wc -l)
  if [ "${NUM_FILES}" -ne "22" ]; then
    >&2 echo "Error: s3 bed/bim files missing."
    exit 1
  fi
}

function create_merged_bim_file_if_not_exist() {
  if ! [ -f s3/all.sorted.bim ]; then
    echo "aggregating s3 files..."
    cat s3/*.bim > s3/all.bim
    echo "sorting aggregate s3 file..."
    sort -k 2,2 s3/all.bim > s3/all.sorted.bim
  fi
}

function decompressed_sumstats_to_bed_if_needed() {
  # in: 
  #  $1 filename (without .gz)
  #  $2 force: bool
  # out: none
  # produces s5/${filename}.bed if none exists
  sumstats=$1
  force=$2
  dodecompression=true
  if ! $force; then
    if [ -f s5/$sumstats.bed ]; then
      dodecompression=false
    fi
  fi
  if $dodecompression; then
    error_if_not_all_bed_files
    create_merged_bim_file_if_not_exist
    echo ""
    echo "Which column of the following sumstats contents"
    echo "(starting from 1) is the SNP or rsid column?"
    echo "You should be seeing the header line, and first data line below."
    echo ""
    head -n2 s5/${sumstats}
    echo ""
    colnum=""
    read -r -p "column [default 1]: " colnum
    if [ -z "$col_num" ]; then
      colnum=1
    fi
    if ! [ "$colnum" -eq "$colnum" ]; then
      >&2 echo "Error: please enter a number or accept the default"
      exit 1
    fi
    $SHELL src/should-be-in-path.sh awk
    $SHELL src/should-be-in-path.sh join
    # remove header line
    tail -n +2 s5/${sumstats} > s5/tempsumstats
    mv s5/tempsumstats s5/${sumstats}
    # proceed with sorting and joining
    echo "sorting s5/${sumstats}"
    sort -k $colnum,$colnum s5/${sumstats} > s5/${sumstats}.sorted
    echo "picking columns and converting to .bed format..."
    echo "  input: s5/${sumstats}"
    echo "  output: s5/${sumstats}.bed"
    join -1 2 -2 $colnum -t$'\t' s3/all.sorted.bim s5/${sumstats}.sorted > s5/joined
    awk -F'\t' -v OFS='\t' '{s=""; for (i=7; i<=NF; i++) {s = s $i OFS}; print($2,$4,$4+1,$1,s)}' s5/joined > s5/${sumstats}.bed
    ### OLD CODE # input: chr	snpid	a1	a2	bp	info	or	se	p	ngt
    ### OLD CODE # output: chr	bp	bp+1	snpid	a1	a2	bp	info	or	se	p	ngt
    ### OLD CODE awk -F'\t' -v OFS="\t" -v s=1 'FNR == 1 {next} {print($1,$5,$5+s,$2,$3,$4,$6,$7,$8,$9,$10)}' s5/$sumstats > s5/$sumstats.bed
    echo "  (finished)"
  else
    echo "s5/$sumstats.bed already exists, skipping conversion to bed"
  fi
}

function liftover_sumstats_to_hg38_if_needed() {
  # in: 
  #  $1 sumstats filename (without ext)
  #  $2 force: bool
  # out: none
  # produces s5/${filename}.hg38.bed
  sumstats=$1
  force=$2
  doliftover=true
  if ! $force; then
    if [ -f s5/$sumstats.hg38.bed ]; then
      doliftover=false
    fi
  fi
  if $doliftover; then
    liftOver -bedPlus=4 s5/$sumstats.bed tools/bin/hg19ToHg38.over.chain.gz s5/$sumstats.hg38.bed s5/unmapped.liftover.log
  else
    echo "s5/$sumstats.hg38.bed already exists, skipping liftover"
  fi
}

function install_bedtools_if_needed() {
  hasbedtools=$($SHELL src/is_tool_installed.sh bedtools)
  if ! $hasbedtools; then
    $SHELL src/install-bedtools.sh
  fi
}

function sort_final_bed_if_needed() {
  # in: 
  #  $1 filename (bed no ext)
  #  $2 force: bool
  # out: none
  # produces sorted bed file
  # only if it ${filename}.sorted.bed doesn't already exist
  bedfile=$1
  force=$2
  bedfilebase=$(basename $bedfile .bed)
  dosorting=true
  if ! $force; then
    if [ -f s5/$bedfilebase.hg38.sorted.bed ]; then
      dosorting=false
    fi
  fi
  if $dosorting; then
    install_bedtools_if_needed
    # sort bed
    echo "sorting s5/$bedfile"
    bedtools sort -i s5/$bedfile.hg38.bed > s5/$bedfilebase.hg38.sorted.bed
    echo "($bedfilebase.hg38.sorted.bed)"
  else
    echo "s5/$bedfilebase.hg38.sorted.bed already exists, skipping sorting"
  fi
}

function convert_sorted_hg38_bed_to_sumstats_if_needed() {
  # in: 
  #  $1 filename (bed no ext)
  #  $2 force: bool
  # out: none
  # produces proper sumstats file
  # only if it ${filename}.hg38.sorted.gz doesn't already exist
  # requires gzip
  bedfile=$1
  force=$2
  bedfilebase=$(basename $bedfile .bed)
  dosumstats=true
  if ! $force; then
    if [ -f s5/$bedfilebase.hg38.sorted.gz ]; then
      dosumstats=false
    fi
  fi
  if $dosumstats; then
    $SHELL src/should-be-in-path.sh awk
    # sort bed
    echo "converting s5/$bedfile.hg38.sorted.bed to sumstats"
    # by recreating the correct column headers
    # then rearranging columns from the sorted bed file to be proper sumstats
    awk -F'\t' -v OFS='\t' 'NR==1{print("hg38chrc","snpid","a1","a2","bp","info","or","se","p","ngt")}{print($1,$4,$5,$6,$2,$7,$8,$9,$10,$11)}' s5/$bedfile.hg38.sorted.bed > s5/$bedfile.hg38.sorted.txt
    $SHELL src/should-be-in-path.sh gzip
    gzip -c s5/$bedfile.hg38.sorted.txt > s5/$bedfile.hg38.sorted.gz
    echo "($bedfilebase.hg38.sorted.gz)"
  else
    echo "s5/$bedfilebase.hg38.sorted.gz already exists, skipping conversion back to sumstats"
  fi
}

function symbolic_link_for_next_phase_if_needed() {
  # in: name of final sumstats file to use
  # out: none
  sumstats_full_name=$1
  force=$2
  dolink=true
  if ! $force; then
    if [ -L s5/sumstats.gz ]; then
      dolink=false
    fi
  fi
  if $dolink; then
    rm -f s5/sumstats.gz
    # (hard link required for ldsc)
    ln s5/$sumstats_full_name s5/sumstats.gz
    echo "prepared sumstats for s8 (s5/sumstats.gz)"
  else
    echo "s5/sumstats.gz already present, skipping generation"
  fi
}

function get_hapmap3_snps_if_needed() {
  # in: none
  # out: none
  # downloads and produces s5/w_hm3.snplist.bz2
  if ! [ -f s5/w_hm3.snplist ]; then
    echo "downloading s5/w_hm3.snplist.bz2"
    $SHELL src/should-be-in-path.sh wget
    wget -L "https://data.broadinstitute.org/alkesgroup/LDSCORE/w_hm3.snplist.bz2" -O s5/w_hm3.snplist.bz2
    $SHELL src/should-be-in-path.sh bunzip2
    # unzipping removes archive
    bunzip2 s5/w_hm3.snplist.bz2
  else
    echo "s5/w_hm3.snplist.bz2 already present, skipping download and unpack"
  fi
}

function check_python_requirements() {
  # in: none
  # out: none
  # errors out if python2, pandas, numpy, scipy, are not installed
  $SHELL src/should-be-in-path.sh python2
  $SHELL src/should-be-in-path.sh pip
  # store all listed modules and versions
  freeze_output=$(pip freeze)
  for ver_string in "pandas==0.17.0" "numpy==1.8.0" "scipy==0.11.0"; do
    module=$(echo ${ver_string} | cut -d'=' -f1)
    # check module can be imported
    python2 -c "import ${module}"
    if [ "$?" -eq "1" ]; then
      >&2 echo "Error: python module '${module}' required."
      >&2 echo "The following set of modules are required for ldsc and can be installed through pip by the following commands:"
      >&2 echo "$ pip install pandas==0.17.0"
      >&2 echo "$ pip install numpy==1.8.0"
      >&2 echo "$ pip install scipy==0.11.0"
      exit 1
    fi
    # check module version
    if [ $ver_string != $(echo $freeze_output | tr -s ' ' '\n' | grep "${module}") ]; then
      >&2 echo "Error: ${module} version is incorrect. Please remove then install using pip:"
      >&2 echo "$ pip uninstall ${module}"
      >&2 echo "$ pip install pandas==0.17.0"
      >&2 echo "$ pip install numpy==1.8.0"
      >&2 echo "$ pip install scipy==0.11.0"
      exit 1
    fi
  done
}

function munge_sumstats() {
  # in:
  #  $1 force
  #  note, assumes file exists now s5/prepared_sumstats.gz was hard-linnked
  # note: requires the following exact packages (installed through pip, NOT conda)
  # pandas==0.17.0
  # numpy==1.8.0 
  # scipy==0.11.0
  check_python_requirements
  # install ldsc tool if necessary
  $SHELL src/install-ldsc.sh
  echo ""
  echo "You're ready to perform the sumstats munge step."
  echo "Use the following command or a variant of it, depending on the numbers from your study that produced the summary statistics."
  echo "python tools/ldsc/munge_sumstats.py --sumstats s5/sumstats.gz --out s5/final_summary_statistics --merge-alleles s5/w_hm3.snplist --a1-inc --N-cas INTEGER_N_CASES --N-con INTEGER_N_CONTROLS"
  echo ""
  echo "  or maybe"
  echo ""
  echo "python tools/ldsc/munge_sumstats.py --sumstats s5/sumstats.gz --out s5/final_summary_statistics --merge-alleles s5/w_hm3.snplist --a1-inc --N INTEGER_N"
  echo ""
  echo "replacing the placeholders as necessary with correct numbers: INTEGER_N_CASES, INTEGER_N_CONTROLS, INTEGER_N"
  echo ""
  echo "for example:"
  echo "python tools/ldsc/munge_sumstats.py --sumstats s5/sumstats.gz --out s5/final_summary_statistics --merge-alleles s5/w_hm3.snplist --a1-inc --N-con 113075 --N-cas 36989"
  echo ""
}

# functions available
# require_liftover()
# decompress_sumstats_if_needed(filename.gz, force)
# decompressed_sumstats_to_bed_if_needed(filename-no-ext, force)
# liftover_sumstats_to_hg38_if_needed(filename-no-ext, force)
# sort_final_bed_if_needed(filename-no-ext, force)
# convert_sorted_hg38_bed_to_sumstats_if_needed(filename-no-ext, force)
# symbolic_link_for_next_phase_if_needed(filename-FULL, force)
# get_hapmap3_snps_if_needed()

function main() {
  # in:
  #  $1 sumstats_compressed:string
  #  $2 genome build format:string (hg19,hg38)
  #  $3 force:boolean
  # out: none
  sumstats_compressed=$1
  format=$(echo $2 | tr '[:upper:]' '[:lower:]')
  force=$3

  case "$force" in
    "-f")
      force=true
      ;;
    "")
      force=false
      ;;
    *)
      >&2 echo "Error: unknown flag '$force'"
      exit 1
  esac

  echo "Using sumstats file $sumstats_compressed"
  case $format in
    "hg19")
      echo "Using hg19 (will perform liftover)"
      ;;
    "hg38")
      echo "Using hg38 (no liftover needed)"
      ;;
    *)
      >&2 echo "Error: Unknown genome build. Valid builds: hg19, hg38"
      exit 1
  esac

  sumstats=$(basename $sumstats_compressed .gz)
  mkdir -p s5
  # do liftover if hg19
  if [ $format = "hg19" ]; then
    require_liftover
    decompress_sumstats_if_needed $sumstats_compressed $force
    decompressed_sumstats_to_bed_if_needed $sumstats $force
    liftover_sumstats_to_hg38_if_needed $sumstats $force
    sort_final_bed_if_needed $sumstats $force
    convert_sorted_hg38_bed_to_sumstats_if_needed $sumstats $force
    symbolic_link_for_next_phase_if_needed $sumstats.hg38.sorted.gz $force
  else
    cp $sumstats_compressed s5/$sumstats.hg38.sorted.gz
    symbolic_link_for_next_phase_if_needed $sumstats.hg38.sorted.gz $force
  fi
  # download hapmap3 snps (s5/w_hm3.snplist)
  get_hapmap3_snps_if_needed
  munge_sumstats
}

main $*
