#!/bin/bash 
set -e
#################
# This is the master code for running CNVnator(v 0.3.2)
################################
# Load the neccessary modules
module use /apps/modulefiles/lab/miket
module load gcc/4.9.0
module load CNVnator/0.3.2
#########################
# This code assumes one input bam file
# This code assumes that a suitable reference directory with (#.fa) 
# for all chromosomes is present
# The usage of this code is as follows
# ./CNVnator.sh -d[output directory, optional, default="."]\
              # -r[Directory of reference,optional,] dir\
              # default="cnvdir=/data/talkowski/Samples/SFARI/deep_sv/joint/cnvnator"]\
              # -o[output file name, optional, default="sample.sv"]
              # -b[bam file, required] xxx.bam
help_message()
{
echo -e "./CNVnator.sh -d[output directory, optional, default="."]\n
              -r[Directory of reference,optional,] dir\n
              default='cnvdir=/data/talkowski/Samples/SFARI/deep_sv/joint/cnvnator']\n
              -o[output file name, optional, default='sample.sv']\n
              -b[bam file, required] xxx.bam"
}
# Set Default Variables
OUT_DIR="."
cnvdir=/data/talkowski/Samples/SFARI/deep_sv/joint/cnvnator  #  Directory where 1.fa, 2.fa etc is stored.
rootfile="out.root"
outputfile="sample.sv"
FLAG=0
#################
#  Parse arguments
if [ $# -eq 0 ];
then
    help_message
    exit 0
else
    while getopts ":hr:d:o:b:" opt; do
        case $opt in
            h ) help_message
                exit 0 ;;
            r ) echo "Reference Directory = $OPTARG" 
                cnvdir=$OPTARG ;;
            d ) echo "Output Directory = $OPTARG" 
                OUT_DIR=$OPTARG
                mkdir -p $OUT_DIR ;;
            o ) echo "Output file = $OPTARG" 
                outputfile=$OUT_DIR$OPTARG ;;
            b ) echo "Bam file = $OPTARG"
                FLAG=1
                bamfile=$OPTARG ;;
            * ) help_message
                exit 1 ;;
        esac
    done
fi
if [ $FLAG -eq 0 ];
then 
    echo "At least one bam file needed."
    exit 1
fi
#  Running the CNVnator pipeline with one sample
#####################
#  Extracting read mapping
###############3
cnvnator -root $rootfile -tree $bamfile
############33
#  A histogram
################
cnvnator -root $rootfile -his 100 -d $cnvdir
###################33
#  Processing
##############33
cnvnator -root $rootfile -stat 100 -d $cnvdir
##############33
#  RD signal partition
#################
cnvnator -root $rootfile -partition 100 -d $cnvdir
#################
#  CNV calling
###################
cnvnator -root $rootfile -call 100 > $outputfile
#  Errors

