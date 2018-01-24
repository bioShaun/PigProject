#!/bin/bash

set -e
set -u
set -o pipefail

# for mapping with star

script_path=$0
sample_file=$1
mapping_dir=$2
ref_flat=$3

if [ "$#" -ne 3 -o ! -r "$1" -o ! -r "$3" ]
then
    echo "usage: ${script_path} sample_inf mapping_dir ref_flat"
    exit 1
fi

sample_names=$(cut -f2 $sample_file)
mapping_matrix_dir=${mapping_dir}/RnaSeqMetrics
picard_path="/public/software/picard/2.17.3/picard.jar"

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${mapping_matrix_dir} ]
    then
        mkdir -p ${mapping_matrix_dir}
    fi
    each_sample_bam="${mapping_dir}/${each_sample}/Aligned.sortedByCoord.out.bam"
    each_sample_matrix="${mapping_matrix_dir}/${each_sample}.RNA_Metrics"
    if [ ! -e ${each_sample_matrix} ]
    then
	echo "#!/bin/bash" > ${mapping_dir}/${each_sample}/map_stat.${each_sample}.sh
	echo "java -jar ${picard_path} CollectRnaSeqMetrics \\
              I=${each_sample_bam} \\
              O=${each_sample_matrix} \\
              REF_FLAT=${ref_flat} \\
              STRAND=SECOND_READ_TRANSCRIPTION_STRAND" >> ${mapping_dir}/${each_sample}/map_stat.${each_sample}.sh
	omsrunone.sh ${mapping_dir}/${each_sample}/map_stat.${each_sample}.sh 2
	#omsrunone.sh ${mapping_dir}/${each_sample}/${each_sample}.matrix.sh 8
    fi
done
