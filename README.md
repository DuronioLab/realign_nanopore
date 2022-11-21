# realign_nanopore

Script to take raw plasmidsaurus nanopore reads for plasmids, re-start each sequence to an artificial start, align to a reference sequence, and generate a consensus sequence.


Within the script, change the following parameters:

An accurate ref sequence for your plasmid with layout: [1/2 vector]-[insert]-[1/2 vector]:
ref_fasta="./plasmid_reference_sequence.fasta"

The 5'-most 60 bases of the ref_fasta sequence:
ref_query="agcggtggccgaaaaacgggcggaaacccttgcaaatgctggattttctgcctgtggaca"

Expected length of plasmid in bp:
plasmid_length=29000

The fastq results from plasmidaurus:
fastq_file="./nanopore_raw.fastq"


To run, move the script into a folder on longleaf along with the reference fasta and fastq file from plasmidsaurus.

Make sure script is executable with:
chmod u+x ./realign_fasta.sh

Run the script with:
sbatch --wrap="sh realign_fasta.sh"
