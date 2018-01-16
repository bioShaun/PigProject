#!/bin/bash

set -e
set -u
set -o pipefail

# for assembly with cufflinks

script_path=$0
gtf=$1
sample_file=$2
mapping_dir=$3
bundle_size=$4

if [ "$#" -ne 4 -o ! -r "$1" ! -r "$2" -o ! -d $3 ]
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
    if [ ! -e ${mapping_dir}/${each_sample}/${each_sample}.sh ]
    then
	echo "#!/bin/bash" > ${mapping_dir}/${each_sample}/${each_sample}.sh
	echo "STAR \\
          --genomeDir ${index} \\
          --readFilesIn ${fq_dir}/${each_sample}_1.clean.fq.gz ${fq_dir}/${each_sample}_2.clean.fq.gz \\
          --readFilesCommand zcat \\
          --outFileNamePrefix ${mapping_dir}/${each_sample}/ \\
          --runThreadN 8 \\
          --outSAMtype BAM SortedByCoordinate \\
          --outFilterType BySJout \\
          --outFilterMultimapNmax 20 \\
          --alignSJoverhangMin 8 \\
          --alignSJDBoverhangMin 1 \\
          --outFilterMismatchNmax 999 \\
          --alignIntronMin 20 \\
          --alignIntronMax 1000000 \\
          --alignMatesGapMax 1000000 \\
          --chimSegmentMin 10" >> ${mapping_dir}/${each_sample}/${each_sample}.sh
    fi
    if [ ! -e ${mapping_dir}/${each_sample}/Log.out ]
    then
	omsrunone.sh ${mapping_dir}/${each_sample}/${each_sample}.sh 8
    fi
done
