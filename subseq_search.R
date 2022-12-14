#Get the arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the current working directory
wd <- getwd()

# Construct the path to the file using the current working directory
file_path <- file.path(wd, args[1])

# Open the input FASTQ file
fasta_file <- file(file_path)

file_text <- readLines(fasta_file)

close(fasta_file)

# extract the header and DNA sequence from the text file
header = sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(file_path))
dna_sequence = file_text[2:length(file_text)]
dna_sequence = paste(dna_sequence, collapse="")

# search the DNA sequence for the specified subsequences
subsequence_list = c("GATC", "CCAGG", "CCTGG")

# create a dataframe to store the found subsequences
df = data.frame(header=character(), start_index=integer(), end_index=integer(), subsequence_num=character())

for (subsequence in subsequence_list) {
  start_index = gregexpr(subsequence, dna_sequence, ignore.case = TRUE)[[1]] - 1
  end_index = start_index + nchar(subsequence)
  subsequence_num = paste(subsequence, "_", 1:length(start_index), sep="")
  df = rbind(df, data.frame(header=header, start_index=start_index, end_index=end_index, subsequence_num=subsequence_num))
}


write.table(df, sep="\t", col.names = FALSE, row.names = FALSE, file = "methylation.bed", quote = FALSE)


# initialize a dataframe to store the results
results <- data.frame()

# search for instances of homopolymer tracts with a length greater than 5
for (i in 1:(nchar(dna_sequence) - 5)) {
  # get a subsequence of length 6
  subsequence <- substr(dna_sequence, i, i+5)
  
  # check if the subsequence is a homopolymer tract
  if (grepl("^(.)\\1+$", subsequence)) {
    # extract the type of homopolymer tract
    type <- substr(subsequence, 1, 1)
    
    if (nrow(results) > 0 && results$end[nrow(results)] >= i && results$type[nrow(results)] == type) {
      # update the end position of the previous homopolymer tract
      results$end[nrow(results)] <- i + 5
    } else {
      # add a new row to the results dataframe
      results <- rbind(results, data.frame(name = header, start = i - 1, end = i + 5, type = paste0(toupper(type), "_", nrow(results)+1)))
    }
  }
}

write.table(results, sep="\t", col.names = FALSE, row.names = FALSE, file = "homopolymer.bed", quote = FALSE)
