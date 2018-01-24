#!/bin/bash

set -e
set -u

sample_file=$1
assembly_dir=$2
merge_dir=$3

if [ "$#" -ne 3 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${0} sample_inf assembly_dir merge_dir"
    exit 1
fi

filter_exp_dir="${merge_dir}/filter_zero"
filter_exp_py="/project0/OM-mRNA-pig-limingzhou-P160901/scripts/filter_exp.py"
script_dir="${filter_exp_dir}/script"

if [ ! -d ${script_dir} ]
then
    mkdir -p ${script_dir}
fi


echo -e "sample_id\tlibrary_id\tgtf_file\tbam_file" > ${filter_exp_dir}/library.file

sample_names=$(cut -f2 ${sample_file})
for each_sample in ${sample_names[@]}
do
    each_filter_exp_gtf=${filter_exp_dir}/${each_sample}.gtf
    echo -e "${each_sample}\t${each_sample}\t${each_filter_exp_gtf}\t${each_filter_exp_gtf}" >> ${filter_exp_dir}/library.file
    each_assembly_gtf=${assembly_dir}/${each_sample}/transcripts.gtf
    if [ ! -e ${each_filter_exp_gtf} -o ! -s ${each_filter_exp_gtf} ]
    then
	echo "#!/bin/bash" > ${script_dir}/${each_sample}.filter_exp.sh
	echo "python ${filter_exp_py} ${each_assembly_gtf} > ${each_filter_exp_gtf}" >> ${script_dir}/${each_sample}.filter_exp.sh
	omsrunone.sh ${script_dir}/${each_sample}.filter_exp.sh 1
    fi
done
    
