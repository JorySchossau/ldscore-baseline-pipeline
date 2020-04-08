
# given a baseline (the one prepared by this pipeline of used was in s3)
# this creates the necessary annot files from lists of snps as snps belonging
# to categories.
# example: bash src/s6-create-annot.sh s3/subset. customannots/* oldannots/*

function merge_annot_files() {
  # in:
  #  $1 bimfilepattern:string
  #  $* annot category files (lists of snps)
  #  $x force:bool
  # out: none
  # performs annot file merging using bim files as base

  force=false
  for arg
  do
    shift
    [ "$arg" = "-f" ] && force=true && continue
    set -- "$@" "$arg"
  done

  # [old] How to use this script
  # for set in s3/subset.{1..22}.bim; do bash test.sh ${set} antisense miRNA lincRNA snoRNA ; done

  bimfilepattern=$1
  shift 1

  runfirsttimecode=true

  for bimfile in $bimfilepattern*.bim; do
    annotfile=s6/$(basename $bimfile .bim).annot

    doannotfile=true
    if ! $force; then
      if [ -f $annotfile ]; then
        doannotfile=false
      fi
    fi
    if $doannotfile; then

      if $runfirsttimecode; then
        # Notify ueser what bim files will be used
        mkdir -p s6
        echo "Beginning Annot creation"
        echo "Using bim file pattern: '$bimfilepattern', which found files:"
        for file in $bimfilepattern*.bim; do
          echo "$file"
        done
        echo ""

        $SHELL src/should-be-in-path.sh dos2unix

        # Data Sanitizing
        # Convert files dos2unix just in case
        for file in $*; do
          dos2unix <$file > tmpfile
          mv tmpfile $file
        done
        runfirsttimecode=false
      fi

      echo "creating $annotfile"

      # THEN perform the join
      #join -1 1 -2 2 -o 2.1,2.4,2.2,2.3 -t"$(printf '\t')" <(cat s6/mastersnplist-sorted | tr -s "\r\n" "\t\n") <(sort -k2,2 $bimfile) > s6/tempannot
      # NOPE just grab columns instead. LDSC wiki: "You can always create an annot file on your own. Make sure you have the same SNPs in the same order as the .bim file used for the computation of LD scores!"
      # rearrange the columns
      echo "  extracting bimfile data"
      awk -F'\t' -v OFS='\t' '{print($1,$4,$2,$3)}' <$bimfile > s6/tempannot

      # add base column (using 'yes' trick)
      echo "  adding base column"
      NUM_ROWS=$(wc -l s6/tempannot | cut -d' ' -f1)
      paste s6/tempannot <(yes "1" | head -n ${NUM_ROWS}) > s6/tempannot-base
      mv s6/tempannot-base s6/tempannot

      cp s6/tempannot s6/tempannot-cumulative
      # Use AWK to load a cat, then for each item in mastersnplist ask if it's in the cat snps. If so, print a '1' otherwise '0'. Then pass that on to the paste command and build the annot file
      echo -ne "  adding categories:"
      for file in $*; do
        echo -ne " ${file}"
        awk -F'\t' -v OFS='\t' 'NR==FNR{F1[$1];next} {if ($3 in F1) print($0"\t1"); else print($0"\t0")}' ${file} s6/tempannot-cumulative > s6/tempannot-next
        mv s6/tempannot-next s6/tempannot-cumulative
      done
      echo ""
      mv s6/tempannot-cumulative $annotfile-unnamed

      # Generate header in new file
      echo "  generating headers"
      echo -ne "CHR\tBP\tSNP\tCM\tbase" > s6/tempannot-named
      for file in $*; do
        echo -ne "\t$(basename ${file})" >> s6/tempannot-named
      done
      echo -ne "\n" >> s6/tempannot-named

      # Append data to new headered file
      cat $annotfile-unnamed >> s6/tempannot-named
      rm $annotfile-unnamed
      mv s6/tempannot-named $annotfile
    else
      echo "$annotfile already present. Skipping annot file creation."
    fi
  done
}

function main() {
  # in:
  #  $1 bimfilepatterh:string
  #  $* annot category files (lists of snps)
  #  $x force:bool
  # out: none
  # performs annot file merging using bim files as base
  merge_annot_files $*
}

main $*
