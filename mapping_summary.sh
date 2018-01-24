#!/bin/bash

set -e
set -u
set -o pipefail

# for mapping with star

script_path=$0
sample_file=$1
rRNA_dir=$2
mapping_dir=$3
name=$4

if [ "$#" -ne 4 -o ! -r "$1" -o ! -d "$2" -o ! -d "$3" ]
then
    echo "usage: ${script_path} sample_inf rRNA_dir mapping_dir"
    exit 1
fi

mapping_matrix_dir=${mapping_dir}/RnaSeqMetrics
script_path="/public/scripts/omsTools/omstools/"

python ${script_path}/RNAseq/general/rnaseq_matrix_summary.py \
    --analysis_dir ${mapping_matrix_dir} \
    -s ${sample_file} \


python ${script_path}/RNAseq/general//mapping_summary.py \
    -s ${sample_file} \
    -d ${mapping_dir}

python ${script_path}/RNAseq/general/rRNA_rate.py \
    ${sample_file} \
    ${rRNA_dir} \
    ${rRNA_dir}/rRNA_rate.txt

python ${script_path}/general/merge_files_by_column.py \
    ${mapping_dir}/star_mapping.summary.txt \
    ${mapping_matrix_dir}/rna_matrix.summary.txt \
    ${rRNA_dir}/rRNA_rate.txt \
    ${mapping_dir}/${name}.star_mapping.detailed.txt
    
