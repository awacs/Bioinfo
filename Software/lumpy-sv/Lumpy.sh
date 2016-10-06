#!/bin/bash
set -e 
# This is the master script for running lumpy-sv (v0.2.13)
# The code assumes existence of /lumpy-sv/scripts/pairend_distro.py script
# This also assumes that lumpy is in PATH
# For detailed options use ./Lumpy.sh
# output is .bedpe file 
# Example usage:
# $./Lumpy.sh -p ../Rawdata/14415.fa.bam -s ../Rawdata/14415.fa.bam
# Load neccessary modules
module use /apps/modulefiles/lab/miket
module load sambamba/0.6.1
help_message()
{
echo -e "./Lumpy.sh -s[split read bam files,optional] s1.bam,s2.bam,... \n
 -p[paired end bam files, optional] s1.bam,s2.bam,... \n  
 -m[min map, optional,default:1] -b [back distance,optional,default:20]\n
 -t [trim threshold,optional,default:1e-3] -r[read distance,optional,default:150]\n
 -l [lumpy-sv directory, optional, default:/PHShome/hw878/Software/lumpy-sv]\n
 -o[output tag,optional,default="lumpy_output"]\n
 -d[output directory,optional,default="."]\n"
}
# Default variables
PE_FLAG=0
SR_FLAG=0
OUT_DIR="."
LUMPY_DIR=/PHShome/hw878/Software/lumpy-sv
OUT="lumpy_output"
WEIGHT=4
Z=4
MIN_MAP_T=1
BACK=20
TT=1e-3
READ_LENGTH=150
FLAG=0  # need at least one bam
# Parse arguments
if [ $# -eq 0 ];
then
    help_message
    exit 1
else
    while getopts ":hs:p:m:b:t:r:o:l:d:" opt; do
        case $opt in
            h ) help_message
                exit 0 ;;
            s ) echo "split read bams = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                sr_array=($OPTARG) ;; # use the split+glob operator
            p ) echo "paired end bams = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                pe_array=($OPTARG) ;; # use the split+glob operator
            m ) echo "min_mapping_threshold = $OPTARG" 
                MIN_MAP_T=$OPTARG ;;
            b ) echo "back distance = $OPTARG" 
                BACK=$OPTARG ;;
            t ) echo "trim threshold = $OPTARG" 
                TT=$OPTARG ;;
            r ) echo "read length = $OPTARG" 
                READ_LENGTH=$OPTARG ;;
            o ) echo "output tag = $OPTARG" 
                OUT=$OPTARG ;;
            d ) echo "output directory = $OPTARG" 
                OUT_DIR=$OPTARG 
                mkdir -p $OUT_DIR ;; 
            l ) echo "lumpy-sv directory = $OPTARG" 
                LUMPY_DIR=$OPTARG 
                ;;
            * ) help_message
                exit 1 ;;
        esac
    done
fi
if [ ! -f "$LUMPY_DIR/scripts/pairend_distro.py" ];
                then
                    echo "$LUMPY_DIR/scripts/pairend_distro.py not found" 
                    exit 1 
                fi
if [ $FLAG -eq 0 ];
then 
    echo "At least one bam file needed."
    exit 1
fi
# Populate pe_option_array
if [ ${pe_array+x} ];  # if at least one paried end bam exist
then 
    pe_option_array=("-pe")
    echo "Paired end bam exist, populating options"
    i=0
    for PE_BAM in ${pe_array[@]}; 
    do
        OUT_FILE=`basename $PE_BAM .bam`
        MEAN_STDEV=`sambamba view $PE_BAM \
				| $LUMPY_DIR/scripts/pairend_distro.py \
					-r $READ_LENGTH \
					-X $Z \
					-N 10000 \
					-o $OUT_DIR/$OUT_FILE.histo`
        MEAN[$i]=`echo $MEAN_STDEV | cut -f1 | cut -d ":" -f2`
        STDEV[$i]=`echo $MEAN_STDEV | cut -f2 | cut -d ":" -f2`
        pe_option_array+=("bam_file:$PE_BAM,histo_file:$OUT_DIR/$OUT_FILE.histo,mean:$MEAN,stdev:$STDEV,read_length:$READ_LENGTH,min_non_overlap:$READ_LENGTH,discordant_z:4,back_distance:$BACK,weight:1,id:1,min_mapping_threshold:$MIN_MAP_T")
        ((i+=1))
    done
fi
# Populate sr_option_array
if [ ${sr_array+x} ]; 
then
    sr_option_array=("-sr")
    echo "Split read exists, populating options"
    for SR_BAM in ${sr_array[@]}; 
    do 
        sr_option_array+=("bam_file:$SR_BAM,back_distance:$BACK,weight:1,id:1,min_mapping_threshold:$MIN_MAP_T")
        done
fi
#Running Lumpy
echo "Running Lumpy"
lumpy \
    -b \
	-mw $WEIGHT \
    -tt $TT \
    "${sr_option_array[@]}" "${pe_option_array[@]}"
    > $OUT_DIR/$OUT.bedpe
