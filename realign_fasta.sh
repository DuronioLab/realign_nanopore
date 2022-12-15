#!/bin/bash

#SBATCH -p general
#SBATCH --ntasks=2
#SBATCH --time=5:00:00
#SBATCH --mem=16g

##########################################################################################
#   Run the script with:                                                                 #
#   sbatch --time=5:00:00 --mem=16g --ntasks=2 --wrap="sh ./scripts/realign_fasta.sh"    #
##########################################################################################

## Concatenate all FASTQ files together
# Find all files in the current directory with the ".fastq" extension
files=$(find . -maxdepth 1 -name "*.fastq" -not -name "*_restart.fastq")

# Concatenate the found files
cat $files > concat.fastq

#Get the FASTA file and its length
ref_fasta=$(find . -name "*.f*a" -print)

plasmid_length=$(tail -n +2 ${ref_fasta} | tr -d ' \n' | wc -m)

# Remove the file extension from the file name
name=$(echo ${ref_fasta})
ref_basename="${name%.*}"

echo "Found FASTA reference file" ${ref_fasta}
echo "The base that will be used for naming is " ${ref_basename}
echo "The size of the reference plasmid is "${plasmid_length}
echo

#Rename each FASTQ read and set up query.fasta
printf "\n Renaming FASTQ reads and generating FASTA file\n"
module purge && module load seqkit

seqkit replace --quiet -p .+ -r "seq_{nr}" concat.fastq > renamed_reads.fastq
seqkit subseq --quiet -r 1:60 ${ref_fasta} > query.fasta

#Filter raw fastq for size (+- 3% predicted size) and convert to FASTA
min=$((plasmid_length*97/100))
max=$((plasmid_length*103/100))

printf "\nTaking all reads that are > "${min}" and < "${max}" basepairs \n"

seqkit seq --quiet --min-len $min --max-len $max renamed_reads.fastq -o out.fastq
seqkit fq2fa --quiet out.fastq -o out.fasta

printf "\nAfter filtering there are this many reads:\n"
echo $(cat out.fastq|wc -l)/4|bc


#Search for reference query
module purge && module load blat
printf "\nPerforming BLAT and restarting sequences\n"
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

#Convert back to FASTQ with fake quality scores
module purge && module load seqtk
seqtk seq -F '#' plasmid_restart.fasta > ${ref_basename}_restart.fastq

#Generate the consensus sequence
module purge && module load medaka
printf "\nPerforming Medaka consensus search\n"
out_folder="${ref_basename}_consensus"

printf "\nMedaka will use the reference FASTA: \n"${ref_fasta}"\n"

medaka_consensus -i ./plasmid_restart.fasta -o ${out_folder} -d ${ref_fasta} -t 1

## Generate some useful information

module purge && module load r

printf "\nGenerating read length histogram\n"

Rscript ./scripts/read_histogram.R ${ref_basename}_restart.fastq

Rscript ./scripts/restart_consensus.R plasmid_restart.fasta

Rscript ./scripts/subseq_search.R ${ref_fasta}

printf "\nRe-naming output Files..."
mv ./${out_folder}/consensus.fasta ./${ref_basename}_consensus.fasta
mv ./${out_folder}/calls_to_draft.bam ./${ref_basename}_reads.bam
mv ./${out_folder}/calls_to_draft.bam.bai ./${ref_basename}_reads.bam.bai

printf "\nRemoving Files..."

#Remove temp files and do some cleaning up
rm ./out.fasta
rm ./temp.fasta
rm ./query.fasta
rm -r ./${out_folder}
rm ./renamed_reads.fastq
rm ./plasmid_restart.fasta
rm ./concat.fastq
rm ./*.fai
rm ./*.mmi
rm ./out.fastq
rm ./output.psl
rm ./blat_names.txt
rm ./fname.txt
rm ./shortened.fasta

mv ./*.out ./scripts

mkdir ./results

mv *.pdf *consensus.fasta *.bam *.bai *_restart.fastq *_Alignment.txt *.bed ./results
cp ${ref_fasta} ./results
zip -r ${ref_basename}_results.zip ./results
