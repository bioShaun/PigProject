#!/bin/bash

set -e
set -u
#set -o pipefail

# for assembly with cufflinks

if [ "$#" -ne 4 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${0} gtf gtf_dir taco_dir prefix"
    exit 1
fi

gtf=$1
gtf_dir=$2
taco_dir=$3
prefix=$4

exp_attr="RPKM"
thread=8

script_dir="${taco_dir}/scripts/"
if [ ! -e ${script_dir} ]
then
    mkdir -p ${script_dir}
fi

ls "${gtf_dir}"/*gtf > "${script_dir}/gtf.files"

taco_script="${script_dir}/taco.sh"
taco_merge="${taco_dir}/${prefix}_merge"
taco_compare="${taco_dir}/${prefix}_compare"
echo "#!/bin/bash" > $taco_script
echo -e "taco_run \\
      -p ${thread} \\
      -o ${taco_merge} \\
      --gtf-expr-attr ${exp_attr} \\
      --filter-min-expr 0 \\
      --isoform-frac 0.1 \\
      --path-kmax 20 \\
      --max-paths 20 \\
      --filter-min-length 250 \\
      ${script_dir}/gtf.files \n" >> ${taco_script}

echo -e "wait\n" >> ${taco_script}

echo -e "taco_refcomp \\
      -o ${taco_compare} \\
      -p ${thread} \\
      -r ${gtf} \\
      -t ${taco_merge}/assembly.gtf " >> ${taco_script}

nohuprun.sh ${taco_script}
