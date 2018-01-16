#! /bin/sh

set -e
set -u
set -o pipefail

if [ "$#" -ne 2  ]
then
    echo "usage: $0 analysis species"
    exit 1
fi

MAIN_DIR='/project0/OM-mRNA-pig-limingzhou-P160901/'
OM_SCRIPT='/public/scripts/OM004script/'

script_dir="${MAIN_DIR}/scripts/"
analysis=$1
species=$2
proj_dir="${MAIN_DIR}/${species}"

# analysis data path
fq_dir=${proj_dir}/fq_data/
gtf_file=${proj_dir}/${species}.genome.gtf
fasta_file=${proj_dir}/${species}.genome.fa
kallisto_idx=${proj_dir}/nef.${species}.tr.fa.kallisto_idx

# analysis directories
rm_rrna_dir=${proj_dir}/rm_rRNA/
star_index_dir=${proj_dir}/star_index/
hisat_index=${proj_dir}/hisat_index/${species}.genome
mapping_dir=${proj_dir}/mapping/
hisat_mapping_dir=${proj_dir}/hisat_mapping/
fc_count_dir=${proj_dir}/fc_counts/
assembly_dir=${proj_dir}/assembly/
scallop_dir=${proj_dir}/scallop/
kallisto_dir=${proj_dir}/kallisto2/
taco_dir=${proj_dir}/taco/

if [ $analysis = "rm_rrna" ]
then 
    ${script_dir}/slurm_rm_rRNA.sh \
	${fq_dir}/name.map \
	${fq_dir}/ \
	${rm_rrna_dir}
elif [ $analysis = 'kallisto' ]
then
    ${script_dir}/slurm_kallisto.sh \
	${fq_dir}/name.map \
	${kallisto_idx} \
	${rm_rrna_dir}/ \
	${kallisto_dir}
elif [ $analysis = "mapping" ]
then 
    ${script_dir}/slurm_mapping.sh \
	${star_index_dir} \
	${fq_dir}/name.map \
	${rm_rrna_dir} \
	${mapping_dir}
elif [ $analysis = "hisat" ]
then
    ${script_dir}/slurm_mapping_hisat.sh \
	${hisat_index} \
	${fq_dir}/name.map \
	${rm_rrna_dir} \
	${hisat_mapping_dir}
elif [ $analysis = 'bundle_size' ]
then
    ${script_dir}/slurm_bundle_size.sh \
	$gtf_file \
	${fq_dir}/name.map \
	${mapping_dir} \
	${fc_count_dir}
elif [ $analysis = 'scallop' ]
then
    ${script_dir}/slurm_scallop.sh \
	${fq_dir}/name.map \
	${mapping_dir} \
	${scallop_dir} 
elif [ $analysis = 'assembly' ]
then
    echo "Generate max_bundle_size file."
    python ${script_dir}/extract_max_count.py \
	${fc_count_dir}
    if [ -e ${assembly_dir}/scripts/ ]
    then
	echo "Check cufflinks logs."
	python "${OM_SCRIPT}/RNAseq/lncRNA/assembly/cufflinks_check.py" \
	    -d "${assembly_dir}/scripts/" \
	    -o "${assembly_dir}/scripts/finished.samples"
	wait
    fi
    echo "launch assembly scripts."
    ${script_dir}/slurm_cufflinks.sh \
	$gtf_file \
	${fq_dir}/name.map \
	${mapping_dir} \
	${assembly_dir} \
	${fc_count_dir}/sample.max.count.txt
elif [ $analysis = 'taco_scallop' ]
then
    ${script_dir}/slurm_taco.sh \
	${gtf_file} \
	${scallop_dir} \
	${taco_dir} \
	"scallop"
else
    echo "analysis not supported!: ${analysis}"
    exit 1
fi
