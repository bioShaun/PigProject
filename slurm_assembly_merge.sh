#!/bin/bash

set -e
set -u

gtf_file=$1
merge_dir=$2

if [ "$#" -ne 2 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${0} gtf_file merge_dir"
    exit 1
fi

filter_exp_dir="${merge_dir}/filter_zero"
filter_se_dir="${merge_dir}/filter_se"
script_dir="${merge_dir}/script"

if [ ! -d ${script_dir} ]
then
    mkdir -p ${script_dir}
fi

echo "#!/bin/bash" > ${script_dir}/merge.sh

if [ ! -e ${merge_dir}/taco_merge/assembly.gtf ]
then
    echo "aggregate_transcripts.py -o ${filter_se_dir} ${gtf_file} ${filter_exp_dir}/library.file" >> ${script_dir}/merge.sh
    echo "annotate_transcripts.py -p 12 ${filter_se_dir}" >> ${script_dir}/merge.sh
    echo "classify_transcripts.py -p 12 ${filter_se_dir}" >> ${script_dir}/merge.sh
    echo "ls ${filter_se_dir}/classify/*expr.gtf > ${filter_se_dir}/exp.gtf.txt" >> ${script_dir}/merge.sh
    echo "taco_run \\
          -p 12 \\
          -o ${merge_dir}/taco_merge \\
          --gtf-expr-attr score \\
          --filter-min-expr 0 \\
          --isoform-frac 0.1 \\
          --path-kmax 20 \\
          --max-paths 20 \\
          --filter-min-length 250 \\
          ${filter_se_dir}/exp.gtf.txt " >> ${script_dir}/merge.sh
fi

if [ ! -e ${merge_dir}/taco_merge/assembly.refcomp.gtf ]
then
    echo "taco_refcomp \\
          -o ${merge_dir}/taco_merge \\
          -p 12 \\
          -r ${gtf_file} \\
          -t ${merge_dir}/taco_merge/assembly.gtf " >> ${script_dir}/merge.sh
fi
nohuprun.sh ${script_dir}/merge.sh
    
