# realign_nanopore script

## Author: Markus Nevil

Raw plasmidsaurus reads have multiple start locations even though the original molecules were circular. This script "restarts" each read using BLAT to search for sequence that should only appear in the vector. By aligning these restarted reads to a reference sequence, a consensus sequence can be generated and scanned for mutations. This is usueful for vectors with multiple repeats of the same sequence, which normally obfuscates which repeat contains mutations.

## Quick Start:

**Note:** I recommend interfacing with Longleaf using a program with a graphic file explorer, such as MobaXterm for Windows

Clone the script into a new directory in your pine directory of Longleaf:

(Substitute with your own information; example username: `jsmith1`, with example plasmid project name `new_plasmid`)

```
cd /pine/scr/[j]/[s]/[jsmith1]

mkdir ./[new_plasmid]
cd ./[new_plasmid]
```

Run the following command to copy the script into the current directory.
```
git clone https://github.com/DuronioLab/realign_nanopore.git && rm -rf ./realign_nanopore/.git && mv ./realign_nanopore/* ./ && rm -r ./realign_nanopore
```

### Collect/Generate neccessary files/parameters

1. Generate a reference FASTA file for your plasmid in your favorite plasmid editor. The linear sequence should start and end in vector, thus having the approximate layout: [1/2 vector]-[insert(s)]-[1/2 vector].

2. Upload your plasmid reference sequence FASTA file.

3. Upload your raw plasmidsaurus FASTQ file(s). Multiple may be uploaded as long as they are named differently.

4. Determine the expected plasmid length, `plasmid_length`

5. Edit the **one required parameter: plasmid length** in the `realign_fasta.sh` file:
```
plasmid_length=78000
```

### Run the script

Run the script with:
```
sbatch --wrap="sh realign_fasta.sh"
```

### Collect the results
Depending on the number of reads, the script should complete within 15 minutes and generate a subdirectory '/plasmid_restart_consensus' (or '/medaka') with the primary results:
1. `consensus.fasta` is the called consensus sequence to be viewed in a plasmid editor against the reference sequence.
2. `calls_to_draft.bam` contains the aligned reads for visualization in a program like IGV to examine any potential mutations.
3. `calls_to_draft.bam.bai` indexed bam required for IGV visualization.

A secondary result is in the original folder:
1. `plasmid_restart.fasta` contains the restarted reads in FASTA format with their original FASTQ names.
