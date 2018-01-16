#!/bin/bash

set -e
set -u
set -o pipefail

# for mapping with hisat

script_path=$0
index=$1
sample_file=$2
fq_dir=$3
mapping_dir=$4

if [ "$#" -ne 4 -o ! -r "$2" ]
then
    echo "usage: ${script_path} star_index sample_inf fastq_dir mapping_dir"
    exit 1
fi

sample_names=$(cut -f2 $sample_file)

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${mapping_dir}/${each_sample} ]
    then
        mkdir -p ${mapping_dir}/${each_sample}
    fi
    each_sample_bam="${mapping_dir}/${each_sample}/Aligned.sortedByCoord.out.bam"
    run_flag=0
    if [ ! -e ${each_sample_bam} ]
    then
	run_flag=1
    # else
    # 	if [ ! -s ${each_sample_bam} ] &&
    # 	    grep "ReadAlignChunk_processChunks" ${mapping_dir}/${each_sample}/${each_sample}.log* > /dev/null
    # 	then
    # 	    run_flag=1
    # 	fi
    fi
    if [ $run_flag -eq 1 ]
    then
	echo "#!/bin/bash" > ${mapping_dir}/${each_sample}/${each_sample}.sh
	echo "hisat2 \\
          -p 8 \\
          -x ${index} \\
          -1 ${fq_dir}/${each_sample}_1.clean.fq.gz \\
          -2 ${fq_dir}/${each_sample}_2.clean.fq.gz \\
          --rna-strandness RF | \\
          samtools view -Sbo ${each_sample_bam} -" >> ${mapping_dir}/${each_sample}/${each_sample}.sh
	#echo "omsrunone.sh ${mapping_dir}/${each_sample}/${each_sample}.sh 8"
	omsrunone.sh ${mapping_dir}/${each_sample}/${each_sample}.sh 8
    fi
done
