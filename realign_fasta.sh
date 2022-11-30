#!/bin/bash

#SBATCH -p general
#SBATCH --ntasks=2
#SBATCH --time=5:00:00
#SBATCH --mem=16g

########################################################################
#                    Change these 3 parameters                         #
########################################################################

ref_fasta="./plasmid_reference_sequence.fasta"
plasmid_length=29000
fastq_file="./nanopore_raw.fastq"

# ref_fasta = an accurate ref sequence for your plasmid with layout: [1/2 vector]-[insert]-[1/2 vector].
# plasmid_length = expected length of plasmid in bp.
# fastq_file = the fastq results from plasmidaurus.

#######################################################################

# Make sure script is executable with:
# chmod u+x ./realign_fasta.sh

#Run the script with:
# sbatch --wrap="sh realign_fasta.sh"

#######################################################################


#Set up query.fasta
module purge && module load seqkit
seqkit replace -p .+ -r "seq_{nr}" ${fastq_file} > renamed_reads.fastq

seqkit subseq -r 1:60 ${ref_fasta} > query.fasta

#Filter raw fastq for size and convert to fasta
min=$((plasmid_length*90/100))
max=$((plasmid_length*110/100))

seqkit seq --min-len $min --max-len $max renamed_reads.fastq -o out.fastq
seqkit fq2fa out.fastq -o out.fasta


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
seqkit grep -n -f fname.txt out.fasta > temp.fasta
seqkit restart -i ${new_start} temp.fasta >> plasmid_restart.fasta
done


#Generate the consensus sequence
module purge && module load medaka

medaka_consensus -i ./plasmid_restart.fasta -d $ref_fasta -t 1 -o plasmid_restart_consensus


#Remove temp files
rm ./renamed_reads.fastq
rm ./query.fasta
rm ./out.fastq
rm ./out.fasta
rm ./output.psl
rm ./blat_names.txt
rm ./fname.txt
rm ./temp.fasta
