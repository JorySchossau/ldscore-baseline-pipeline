# Uses ldsc to compute the partitioned ldscore
# Relies on files from  steps 3 and 6 (s3, s6)
# internal command: tools/ldsc/ldsc.py --bfile s3/subset.${chr} --ld-wind-kb 100 --l2 --out s6/subset.${chr} --annot s6/subset.${chr}.annot

function calculate_ldscores_if_needed() {
  # in: force:boolean
  # out: none
  # performs ldscore calculation if files don't exist
  # or if force flag passed
  threads=1
  readthreadsarg=false
  force=false
  for arg
  do
    shift
    if $readthreadsarg; then
      readthreadsarg=false
      threads=$arg
      continue
    fi
    #[ $readthreadsarg ] && threads=$arg && readthreadsarg=false && continue
    [ "$arg" = "-f" ] && force=true && continue
    [ "$arg" = "-j" ] && readthreadsarg=true && continue
    set -- "$@" "$arg"
  done

  echo "Beginning ld score estimation (from files in s6)"
  echo "Using ${threads} threads"

  $SHELL src/should-be-in-path.sh parallel

  # collect which chromosomes yet need processing
  # this is affected by the -f force flag, or if files already exist and
  # computation is not being -f forced.
  # space-separated list of chromosome numbers that don't have ldscore files completed yet
  chrToProcessPartitioned=""
  chrToProcessNonPartitioned=""

  # partitioned
  for chr in $(seq 1 22); do
    # partitioned
    doldcalc=true
    if ! $force; then
      if [ -f s6/subset.${chr}.l2.ldscore.gz ]; then
        doldcalc=false
      fi
    fi
    if $doldcalc; then
      chrToProcessPartitioned="${chrToProcessPartitioned} $chr"
    else
      echo "s6/subset.${chr}.l2.ldscore.gz already exists, skipping."
    fi

    # nonpartitioned
    doldcalc=true
    if ! $force; then
      if [ -f s6/subset.nonpart.${chr}.l2.ldscore.gz ]; then
        doldcalc=false
      fi
    fi
    if $doldcalc; then
      chrToProcessNonPartitioned="${chrToProcessNonPartitioned} $chr"
    else
      echo "s6/subset.nonpart.${chr}.l2.ldscore.gz already exists, skipping."
    fi
  done

  # construct all ldsc.py invokation commands needed, by chromosome
  command_buffer_partitioned_ldsc=""
  for chr in $chrToProcessPartitioned; do
    # bash_command#bash_command#etc.
    # then transform into
    # echo bash_command\nbash_command | xargs ...
    #command_buffer_partitioned_ldsc="$command_buffer_partitioned_ldsc#\"echo 'starting partitioned ldsc for chr ${chr}'; python tools/ldsc/ldsc.py --bfile s3/subset.${chr} --ld-wind-kb 100 --l2 --out s6/subset.${chr} --annot s6/subset.${chr}.annot\""
    command_buffer_partitioned_ldsc="$command_buffer_partitioned_ldsc#\"echo 'starting partitioned ldsc for chr ${chr}'; python tools/ldsc/ldsc.py --bfile s3/subset.${chr} --ld-wind-cm 1 --l2 --out s6/subset.${chr} --annot s6/subset.${chr}.annot\""
  done

  command_buffer_nonpartitioned_ldsc=""
  for chr in $chrToProcessNonPartitioned; do
    #command_buffer_nonpartitioned_ldsc="$command_buffer_nonpartitioned_ldsc#\"echo 'starting non-partitioned ldsc for chr ${chr}'; python tools/ldsc/ldsc.py --bfile s3/subset.${chr} --ld-wind-kb 100 --l2 --out s6/subset.nonpart.${chr}\""
    command_buffer_nonpartitioned_ldsc="$command_buffer_nonpartitioned_ldsc#\"echo 'starting non-partitioned ldsc for chr ${chr}'; python tools/ldsc/ldsc.py --bfile s3/subset.${chr} --ld-wind-cm 1 --l2 --out s6/subset.nonpart.${chr}\""
  done

  # run parallelized ldsc depending how many threads user asked for
  echo ${command_buffer_partitioned_ldsc} | tr '#' '\n' | xargs -I CMD -n 1 -P ${threads} bash -c CMD
  echo ${command_buffer_nonpartitioned_ldsc} | tr '#' '\n' | xargs -I CMD -n 1 -P ${threads} bash -c CMD
}

function main() {
  calculate_ldscores_if_needed $*
}

main $*
