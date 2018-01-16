#!/bin/bash

set -e
set -u
set -o pipefail

# for assembly with cufflinks

if [ "$#" -lt 4 -o "$#" -gt 5 -o ! -r "$1" -o ! -r "$2" -o ! -d $3 ]
then
    echo "usage: ${0} gtf sample_inf mapping_dir featureCount_dir strand(default=2)"
    exit 1
fi

gtf=$1
sample_file=$2
mapping_dir=$3
fc_dir=$4
strand=${5:-2}

sample_names=$(cut -f2 $sample_file)
script_dir=${fc_dir}/scripts/

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${script_dir} ]
    then
        mkdir -p ${script_dir}
    fi
    each_counts="${fc_dir}/${each_sample}.counts"
    each_bam="${mapping_dir}/${each_sample}/Aligned.sortedByCoord.out.bam"
    if [ ! -e ${each_counts} -a -s ${each_bam} ]
    then
	echo "#!/bin/bash" > ${script_dir}/${each_sample}.sh
	echo "featureCounts \\
          -T 4 \\
          -p \\
          -t exon \\
          -g gene_id \\
          -a ${gtf} \\
          -M \\
          -s ${strand} \\
          -o ${fc_dir}/${each_sample}.counts \\
          ${mapping_dir}/${each_sample}/Aligned.sortedByCoord.out.bam" >> ${script_dir}/${each_sample}.sh
    	omsrunone.sh ${script_dir}/${each_sample}.sh 4
	#echo "omsrunone.sh ${script_dir}/${each_sample}.sh 4"
    fi
done
