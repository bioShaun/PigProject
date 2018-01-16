#!/bin/bash

set -e
set -u
set -o pipefail

# for mapping with star

script_path=$0
index="/public/database/silva/silva128_rfam"
sample_file=$1
fq_dir=$2
rRNA_rmdir=$3

if [ "$#" -ne 3 -o ! -r "$1" ]
then
    echo "usage: ${script_path} sample_inf fastq_dir rRNA_rmdir"
    exit 1
fi

sample_names=$(cut -f2 $sample_file)

for each_sample in ${sample_names[@]}
do
    if [ ! -d ${rRNA_rmdir}/scripts/ ]
    then
        mkdir -p ${rRNA_rmdir}/scripts
    fi
    run_flag=0
    # check script log
    each_sample_log=${rRNA_rmdir}/${each_sample}.log
    if [ -e ${each_sample_log} ]
    then
	if grep 'Argument' ${each_sample_log} > /dev/null
	then
	    echo "${each_sample} need re-run."
	    run_flag=1
	fi
    else
	echo "${each_sample} need run."
	run_flag=1
    fi
    # check script log
    if [ $run_flag -eq 1 ]
    then
	echo "#!/bin/bash" > ${rRNA_rmdir}/scripts/${each_sample}.sh
	echo "bowtie2 \\
          --reorder \\
          --very-sensitive-local \\
          -x ${index} \\
          -1 ${fq_dir}/${each_sample}_1.clean.fq.gz \\
          -2 ${fq_dir}/${each_sample}_2.clean.fq.gz \\
          -p 8 \\
          --met-file ${rRNA_rmdir}/${each_sample}.metrix \\
          --un-conc-gz ${rRNA_rmdir}/${each_sample}_%.clean.fq.gz \\
          --no-unal \\
          --no-head \\
          --no-sq \\
          --fr \\
          --nofw \\
          -S ${rRNA_rmdir}/${each_sample}.sam > ${rRNA_rmdir}/${each_sample}.log 2>&1" >> ${rRNA_rmdir}/scripts/${each_sample}.sh
	omsrunone.sh ${rRNA_rmdir}/scripts/${each_sample}.sh 8
    fi
done
