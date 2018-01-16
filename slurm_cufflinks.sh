#!/bin/bash

set -e
set -u
#set -o pipefail

# for assembly with cufflinks

if [ "$#" -lt 5 -o "$#" -gt 6 -o ! -r "$1" -o ! -r "$2" -o ! -d "$3"  -o ! -r "$5" ]
then
    echo "usage: ${0} gtf sample_inf mapping_dir assembly_dir bundle_size_file strand(default=2)"
    exit 1
fi

gtf=$1
sample_file=$2
mapping_dir=$3
assembly_dir=$4
bundle_size=$5
strand=${6:-"fr-firststrand"}

sample_names=$(cut -f2 $sample_file)
script_dir=${assembly_dir}/scripts/
finished_samples=${script_dir}/finished.samples

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${script_dir} ]
    then
        mkdir -p ${script_dir}
    fi
    each_sample_bz=$(grep ${each_sample} ${bundle_size} | cut -f2)
    if [ ! $each_sample_bz ]
    then
	echo "${each_sample} Bundle size not calculated."
	continue
    fi
    each_sample_bz=$((${each_sample_bz} * 2))
    each_sample_dir="${assembly_dir}/${each_sample}"
    each_bam="${mapping_dir}/${each_sample}/Aligned.sortedByCoord.out.bam"
    if [ ! -d ${each_sample_dir} ]
    then
	mkdir -p ${each_sample_dir}
    fi
    if [ ! -s ${each_bam} ]
    then
	echo "${each_bam} Not Valid."
    elif [ -e ${finished_samples} ] && 
	grep ${each_sample} ${finished_samples} > /dev/null 
    then
	echo "${each_sample} assembly finished!"
    else
	echo "#!/bin/bash" > ${script_dir}/${each_sample}.sh
	echo "cufflinks \\
          --max-bundle-frags ${each_sample_bz} \\
          -p 8 \\
          -g ${gtf} \\
          --library-type ${strand} \\
          -o ${each_sample_dir} \\
          ${each_bam}" >> ${script_dir}/${each_sample}.sh
    	omsrunone.sh ${script_dir}/${each_sample}.sh 8
	#echo "omsrunone.sh ${script_dir}/${each_sample}.sh 8"
    fi
done
