#!/bin/bash

set -e
set -u
set -o pipefail

script_path=$0
genome_file=$1
merge_dir=$2
species=$3

if [ "$#" -ne 3 -o ! -r "$1" -o ! -d "$2" ]
then
    echo "usage: ${script_path} genome_file merge_dir species"
    exit 1
fi

script_path="/public/scripts/omsTools/omstools/"
cp_dir="${merge_dir}/filter_lnc"
cpc_pred="${cp_dir}/lncrna.candidates.cpc.predict"
run_script="${cp_dir}/extract_lnc.sh"
taco_merge_dir=${merge_dir}/taco_merge
rp_end_gtf=${taco_merge_dir}/assembly.refcomp.rep_end.gtf

# step1
# extract coding transcript from cpc prediction
# and pfam scan

awk '$7=="coding"' ${cpc_pred} | cut -f1 > "${cp_dir}/cpc.coding.list"
cat ${cp_dir}/pfam_out/*pfamA | grep -v "^#"  | awk '{if ($1 != "") {print $1}}' | sed -re 's/_\w+//' |sort -u > ${cp_dir}/pfam.coding.list
cat ${cp_dir}/cpc.coding.list ${cp_dir}/pfam.coding.list | sort -u > ${cp_dir}/all.coding.list

# step2
# extract lncRNA & TUCP gtf and fasta

echo "#!/bin/bash" > ${run_script}

echo "python ${script_path}/general/exclude_id_from_gtf.py \\
    --gtf ${cp_dir}/lncrna.candidates.gtf \\
    --id_file ${cp_dir}/all.coding.list \\
    --flag de \\
    --output ${cp_dir}/lncRNA.gtf
" >> ${run_script}

echo "python ${script_path}/general/exclude_id_from_gtf.py \\
    --gtf ${cp_dir}/lncrna.candidates.gtf \\
    --id_file ${cp_dir}/all.coding.list \\
    --flag ex \\
    --output ${cp_dir}/tucp.gtf
" >> ${run_script}

echo "gffread ${cp_dir}/lncRNA.gtf -g ${genome_file} -w ${cp_dir}/lncRNA.fa" >> ${run_script}
echo "gffread ${cp_dir}/tucp.gtf -g ${genome_file} -w ${cp_dir}/tucp.fa" >> ${run_script}

# build kallisto index for assembly
echo "gffread ${rp_end_gtf} -g ${genome_file} -w ${taco_merge_dir}/assembly.fa" >> ${run_script}
echo "kallisto index -i ${taco_merge_dir}/assembly.fa.kallisto_idx ${taco_merge_dir}/assembly.fa" >> ${run_script}
echo "ln -s ${taco_merge_dir}/assembly.fa.kallisto_idx ${merge_dir}/../${species}.tr.fa.kallisto_idx" >> ${run_script}

nohuprun.sh ${run_script}
