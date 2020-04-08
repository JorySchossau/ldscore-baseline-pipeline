# performs the final regression step (single core computation and fairly quick)
# command: python tools/ldsc/ldsc.py --h2 s5/final_summary_statistics.sumstats.gz --ref-ld-chr s6/subset. --w-ld-chr ../weights_hm3_no_hla/weights. --frqfile-chr s4/subset. --overlap-annot --out results

function calculate_regression_if_needed() {
  # in: force:boolean
  # out: none
  # performs ldscore regression if files don't exist
  # or if force flag passed
  # produces: results.log
  force=false
  for arg
  do
    shift
    [ "$arg" = "-f" ] && force=true && continue
    set -- "$@" "$arg"
  done

  echo "Beginning ld score regression (from files in s6)"

  $SHELL src/should-be-in-path.sh parallel

  # collect which chromosomes yet need processing
  # this is affected by the -f force flag, or if files already exist and
  # computation is not being -f forced.
  # space-separated list of chromosome numbers that don't have ldscore files completed yet
  doldcalc=true
  if ! $force; then
    if [ -f results.log ]; then
      doldcalc=false
    fi
  fi
  if $doldcalc; then
    echo "Performing ldscore regression..."
    #python tools/ldsc/ldsc.py --h2 s5/final_summary_statistics.sumstats.gz --ref-ld-chr s6/subset. --w-ld-chr ../weights_hm3_no_hla/weights. --frqfile-chr s4/subset. --overlap-annot --out results
    python tools/ldsc/ldsc.py --h2 s5/final_summary_statistics.sumstats.gz --ref-ld-chr s6/subset. --w-ld-chr s6/subset.nonpart. --frqfile-chr s4/subset. --overlap-annot --out results
    #python tools/ldsc/ldsc.py --h2 s5/final_summary_statistics.sumstats.gz --ref-ld-chr s6/subset. --w-ld-chr s6/subset. --frqfile-chr s4/subset. --overlap-annot --out results
  else
    echo "results.log (result of regression) already exists, skipping."
  fi

}

function main() {
  calculate_regression_if_needed $*
}

main $*
