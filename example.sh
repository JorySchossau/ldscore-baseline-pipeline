# NOTE that you might get throttled by your internet provider or University
# because this is a lot of data

# install all required tools for all stages
bash src/install-tools.sh

# download 1k genomes vcf data for all populations
bash src/s1-dl-1kg-data.sh

# subset that data via interactive prompt for pop codes
bash src/s2-subset-pop.sh

# perform a conversion of vcf to plink/bed files
bash src/s3-vcf-to-plink.sh

# perform a conversion of vcf to frq files
bash src/s4-vcf-to-frq.sh

# copy the summary statistics into the right place, performing a liftover if necessary (for hg19 it is necessary)
bash src/s5-provide-summary-statistics.sh pgc.scz2.fullsnps.gz hg19

# the end of previous stage says to now do munge_sumstats filling in the N-con and N-cas numbers as needed for your particular study.
python tools/ldsc/munge_sumstats.py --sumstats s5/sumstats.gz --out s5/final_summary_statistics --merge-alleles s5/w_hm3.snplist --a1-inc --N-con 113075 --N-cas 36989

# create custom annot files ready for ldsc, using some custom categories
bash src/s6-create-annot.sh s3/subset. customannots/* oldannots/*

# create the ldscores (partitioned and non-partitioned - partitioned takes a long time, aprox. 10 hrs for chr1, so batch of 8 at a time if possible.)
bash src/s7-create-ldscores.sh -j 8

# perform the regression (fairly quick - but need to discuss options tweak w/ Brad)
bash src/s8-do-regression.sh
