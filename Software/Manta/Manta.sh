#!/bin/bash
set -e
# This code is to run the manta workflow
# This code assumes the manta installation path is known
##################
help_message()
{
echo -e "./Manta.sh -b[bam,requried] -r [.fa reference, required] -o [outputdirectory,optional,default="."]"
}
module use /apps/modulefiles/lab/miket
module load manta/0.29.5
# Default Variables
OUT_DIR="."
# Argument parsing
if [ $# -eq 0 ];
then
    help_message
    exit 1
else
    while getopts ":he:r:o:" opt; do
        case $opt in
            h ) help_message
                exit 0 ;;
            e ) echo "bams = $OPTARG "
                set -f # disable glob
                IFS=',' # split on space characters
                BAMFILE=$OPTARG ;; # use the split+glob operator
            r ) echo "REFERENCE = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                REFFA=$OPTARG ;; # use the split+glob operator
            o ) echo "output directory = $OPTARG" 
                OUT_DIR=$OPTARG 
                mkdir -p $OUT_DIR ;; 
            * ) help_message
                exit 1 ;;
        esac
    done
fi
# CONFIGURATION STEP
configManta.py \
    --bam $BAMFILE \
    --referenceFasta $REFFA \
    --runDir $OUT_DIR
# Running Step
$OUT_DIR/runWorkflow.py -m sge 
