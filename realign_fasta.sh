#!/bin/bash

#SBATCH -p general
#SBATCH --ntasks=2
#SBATCH --time=5:00:00
#SBATCH --mem=16g

########################################################################
#                    Change this parameter!!                           #
#        plasmid_length = expected length of plasmid in bp.            #
########################################################################

plasmid_length=72873

#######################################################################
# Make sure script is executable with:
# chmod u+x ./realign_fasta.sh

#Run the script with:
# sbatch --wrap="sh realign_fasta.sh"
#######################################################################

#Concatenate all FASTQ files together
cat ./*.fastq > concat.fastq

#Get the FASTA file

ref_fasta="*.f*a"
echo "Found FASTA reference file" ${ref_fasta}

#Rename each FASTQ read and set up query.fasta
module purge && module load seqkit

seqkit replace --quiet -p .+ -r "seq_{nr}" concat.fastq > renamed_reads.fastq
seqkit subseq --quiet -r 1:60 ${ref_fasta} > query.fasta

#Filter raw fastq for size (+- 5% predicted size) and convert to FASTA
min=$((plasmid_length*95/100))
max=$((plasmid_length*105/100))

seqkit seq --quiet --min-len $min --max-len $max renamed_reads.fastq -o out.fastq
seqkit fq2fa --quiet out.fastq -o out.fasta


#Search for reference query
module purge && module load blat

blat out.fasta query.fasta -oneOff=3 -noHead output.psl
awk 'NR > 6 {print $14}' output.psl > blat_names.txt


#For each read, restart based on blat
module load seqkit

readarray -t File < blat_names.txt
for f in "${File[@]}"
do
new_start=$(grep -w ${f} output.psl | awk '{print $16}')
echo ${f} > fname.txt
seqkit grep --quiet -n -f fname.txt out.fasta > temp.fasta
seqkit restart --quiet -i ${new_start} temp.fasta >> plasmid_restart.fasta
done


#Generate the consensus sequence
module purge && module load medaka
medaka_consensus -i ./plasmid_restart.fasta -d ${ref_fasta} -t 1 -o plasmid_restart_consensus

echo "Removing Files..."

#Remove temp files
rm ./renamed_reads.fastq
rm ./concat.fastq
rm ./*.fai
rm ./*.mmi
rm ./query.fasta
rm ./out.fastq
rm ./out.fasta
rm ./output.psl
rm ./blat_names.txt
rm ./fname.txt
rm ./temp.fasta
