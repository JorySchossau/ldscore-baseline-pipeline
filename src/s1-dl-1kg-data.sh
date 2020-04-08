mkdir -p s1/1kg
echo "Downloading genotype vcf data from 1000genomes"
HG38SERVER="http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/"
HG19SERVER="http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/"
PANEL="integrated_call_samples_v3.20130502.ALL.panel"
for chrn in $(seq 22 -1 1); do
  # change vv
  filename="ALL.chr${chrn}_GRCh38.genotypes.20170504.vcf.gz" # hg38
  #filename="ALL.chr${chrn}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz" # hg19
  # change ^^
  # skip if file already exists
  if [ -f "s1/1kg/${filename}" ]; then
    echo "${filename} exists, skipping."
    continue
  fi
  # change vv
  URL="${HG38SERVER}${filename}"
  # change ^^
  #wget --quiet -L "${URL}"
  # Their server is so slow with single connection downloads.
  # So wget is out of the question.
  # Let's use axel instead to spead it up 2x (-n 2)
  # that will approach bandwidth limit they have set
  # on public downloads from 1000genomoes.ebi.ac.uk
  # but they also limit how many people download, so sometimes
  # we just get an error and have to try again.
  # The following loop will guarantee success.
  NOT_SUCCESSFUL=1
  while [[ $NOT_SUCCESSFUL > 0 ]]
  do 
    # try to invoke dual-connection download
    axel -a -n 2 ${URL} -o s1/1kg/${filename}
    # store error code (success state)
    NOT_SUCCESSFUL=$?
    # be at least a TINY BIT nice to their server
    # and wait 10 seconds :)
    if [ ${chrn} = "22" ]; then
      continue;
    else
      sleep 10
    fi
  done
done
if [ ! -f "s1/1kg/samples.panel" ]; then
  sleep 10
  wget -L -O s1/1kg/samples.panel "${HG19SERVER}${PANEL}"
else
    echo "samples.panel exists, skipping."
fi
echo "stage 1 finished"
