#!/bin/bash

set -e
set -u
set -o pipefail

# for mapping with star

script_path=$0
genome_file=$1
merge_dir=$2

if [ "$#" -ne 2 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${script_path} genome_file merge_dir"
    exit 1
fi

script_path="/public/scripts/omsTools/omstools/"
cp_dir="${merge_dir}/filter_lnc"
cp_script=${cp_dir}/run_coding_potential.sh

taco_merge_dir=${merge_dir}/taco_merge
ref_cmp_gtf=${taco_merge_dir}/assembly.refcomp.gtf
rp_end_gtf=${taco_merge_dir}/assembly.refcomp.rep_end.gtf
meta_table=${taco_merge_dir}/assembly.metadata.tsv

if [ ! -d ${cp_dir} ]
then
    mkdir -p ${cp_dir}
fi

# init script
echo "#!/bin/bash" > ${cp_script}

# build genome index
if [ ! -e ${genome_file}.fai ]
then
    echo "samtools faidx ${genome_file}" >> ${cp_script}
fi

# extract lncrna candidates
awk '{if ($11 == "lncrna") {print $1}}' ${meta_table} > ${cp_dir}/lncrna.candidates.list


# step1
# correct some record of taco output gtf
# ends beyond the chromosome/scaffold limit

if [ ! -e ${rp_end_gtf} -o ! -s ${rp_end_gtf} ]
then
    echo "python ${script_path}/general/repair_gtf_end.py \\
	${genome_file}.fai \\
	${ref_cmp_gtf} > ${rp_end_gtf} " >> ${cp_script}
fi


# step2
# extract gtf of lncrna candidates from total rna gtf

lncrna_can_gtf=${cp_dir}/lncrna.candidates.gtf
if [ ! -e ${lncrna_can_gtf} -o ! -s ${lncrna_can_gtf} ]
then
    echo "python ${script_path}/general/exclude_id_from_gtf.py \\
	--gtf ${rp_end_gtf} \\
	--id_file ${cp_dir}/lncrna.candidates.list \\
	--output ${lncrna_can_gtf} " >> ${cp_script}
fi

# step3
# predict orf of lncrna candidates

lncrna_can_orf=${cp_dir}/lncrna.candidates.orf.fa

if [ ! -e ${lncrna_can_orf} -o ! -s ${lncrna_can_orf} ]
then
    echo "gffread ${lncrna_can_gtf} \\
	-g ${genome_file} \\
	-w ${cp_dir}/lncrna.candidates.fa " >> ${cp_script}

    echo "getorf \\
	-sequence ${cp_dir}/lncrna.candidates.fa \\
	-outseq ${lncrna_can_orf} \\
	-noreverse " >> ${cp_script}
fi

# step4
# run pfam and cpc2 to predict coding poteintial

## split fa for pfam
split_orf_dir=${cp_dir}/split_orf/

is_empty_dir(){ 
    return `ls -A $1|wc -w`
}

if [ ! -d ${split_orf_dir} ] || is_empty_dir ${split_orf_dir}
then
    echo "python ${script_path}/general/fa_split.py \\
	${lncrna_can_orf} \\
	50000 \\
	${split_orf_dir} " >> ${cp_script}
fi

## run pfam
pfam_dir=${cp_dir}/pfam_out/

if [ ! -d ${pfam_dir} ] || is_empty_dir ${pfam_dir}
then
    echo "python ${script_path}/RNAseq/lncRNA/filter/pfam_huge.py \\
	${split_orf_dir} \\
	${pfam_dir} " >> ${cp_script}
fi

## run cpc2
cpc_out=${cp_dir}/lncrna.candidates.cpc.predict

if [ ! -e ${cpc_out} ]
then
    echo "CPC2.py \\
	-i ${cp_dir}/lncrna.candidates.fa \\
	-o ${cpc_out} " >> ${cp_script}
fi

nohuprun.sh ${cp_script}
    
