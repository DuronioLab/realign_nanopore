# Re-start Nanopore reads and generate a consensus sequence for repetitive plasmids

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
git clone https://github.com/DuronioLab/realign_nanopore.git && rm -rf ./realign_nanopore/.git && mv ./realign_nanopore/* ./ && rm -r ./realign_nanopore && rm -r ./images
```

### Collect/Generate neccessary files/parameters

1. Generate a reference FASTA file for your plasmid in your favorite plasmid editor.
   - The linear sequence should start and end in vector, thus having the approximate layout: [1/2 vector]-[insert(s)]-[1/2 vector]:
   
   ![Like This](https://github.com/DuronioLab/realign_nanopore/blob/main/images/githubAsset%202small.png?raw=true)
2. Upload your plasmid reference sequence FASTA file.

3. Upload your raw plasmidsaurus FASTQ file(s). Multiple may be uploaded as long as they are named differently.

4. Determine the expected plasmid length, open the `realign_fasta.sh` file and edit the `plasmid_length` parameter:

```
plasmid_length=78000
```

After uploading your FASTA and FASTQ files and copying the scripts from github, your file directory should look like:
```
pine/scr/j/s/jsmith1/
├─ new_plasmid/
│  ├─ reference_plasmid.fasta
│  ├─ raw_reads.fastq
│  ├─ README.md
│  ├─ realign_fasta.sh
│  ├─ read_histogram.R
```
**note: you may have more than one FASTQ file, but may only have one reference FASTA file**


### Run the script

Run the script with:
```
sbatch --wrap="sh realign_fasta.sh"
```

### Collect the results
Depending on the number of reads, the script should complete within 30 minutes and generate several results (named after your reference file):
1. `[reference]_consensus.fasta` is the called consensus sequence to be viewed in a plasmid editor against the reference sequence.
2. `[reference]_reads.bam` contains the aligned reads for visualization in a program like IGV to examine any potential mutations.
3. `[reference]_reads.bam.bai` indexed bam required for IGV visualization.
4. `[reference]_restart.fastq` are the re-started, size-filtered FASTQ reads.
5. `Filtered_read_lengths.pdf` is a histogram of the read lengths filtered out by the script. Useful to check size filter stringincy.
6. `Restart_Alignment.txt` is an alignment of the beginnings of the first few reads. Useful to ensure the reads are "re-starting" properly

