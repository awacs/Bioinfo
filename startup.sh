#!/bin/bash -l
module use /apps/modulefiles/lab/miket

bsub -Is -R 'rusage[mem=10000]' -n 4 /bin/bash