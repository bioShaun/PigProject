#!/bin/bash

set -e
set -u
#set -o pipefail

# for assembly with cufflinks

if [ "$#" -lt 3 -o "$#" -gt 5 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${0} sample_inf mapping_dir assembly_dir strand(default=first)"
    exit 1
fi

sample_file=$1
mapping_dir=$2
assembly_dir=$3
strand=${4:-"first"}

sample_names=$(cut -f2 $sample_file)
script_dir=${assembly_dir}/scripts/

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${script_dir} ]
    then
        mkdir -p ${script_dir}
    fi
    each_sample_gtf="${assembly_dir}/${each_sample}.gtf"
    each_bam="${mapping_dir}/${each_sample}.bam"
    if [ ! -s ${each_bam} ]
    then
	echo "${each_bam} Not Valid."
    elif [ -e ${each_sample_gtf} ]
    then
	echo "${each_sample} assembly finished!"
    else
	echo "#!/bin/bash" > ${script_dir}/${each_sample}.sh
	echo "scallop \\
          --library_type ${strand} \\
          -i ${each_bam} \\
          -o ${each_sample_gtf} " >> ${script_dir}/${each_sample}.sh
    	omsrunone.sh ${script_dir}/${each_sample}.sh 2
	#echo "omsrunone.sh ${script_dir}/${each_sample}.sh 2"
    fi
done
