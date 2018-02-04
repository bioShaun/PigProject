#!/bin/bash

set -e
set -u
#set -o pipefail

# for assembly with cufflinks

if [ "$#" -lt 4 -o "$#" -gt 5 -o ! -r "$1" -o ! -r "$2" -o ! -d "$3" ]
then
    echo "usage: ${0} sample_inf kallisto_idx fq_dir kallisto_dir strand(default=first)"
    exit 1
fi

sample_file=$1
kallisto_idx=$2
fq_dir=$3
kallisto_dir=$4
strand=${5:-"--rf-stranded"}

sample_names=$(cut -f2 $sample_file)
script_dir=${kallisto_dir}/scripts/

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${script_dir} ]
    then
        mkdir -p ${script_dir}
    fi
    each_sample_dir="${kallisto_dir}/${each_sample}/"
    each_sample_out="${kallisto_dir}/${each_sample}/abundance.tsv"
    if [ -e ${each_sample_out} ]
    then
	echo "${each_sample} kallisto quant finished!"
    else
	echo "#!/bin/bash" > ${script_dir}/${each_sample}.sh
	echo "kallisto quant \\
          --threads 4 \\
          -i ${kallisto_idx} \\
          --output-dir=${each_sample_dir} \\
          ${strand} \\
          ${fq_dir}/${each_sample}_1.clean.fq.gz \\
          ${fq_dir}/${each_sample}_2.clean.fq.gz " >> ${script_dir}/${each_sample}.sh
    	omsrunone.sh ${script_dir}/${each_sample}.sh 4
	#echo "omsrunone.sh ${script_dir}/${each_sample}.sh 4"
    fi
done
