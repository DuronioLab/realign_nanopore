#Get the arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the current working directory
wd <- getwd()

# Construct the path to the file using the current working directory
file_path <- file.path(wd, args[1])

# Open the input FASTQ file
input_file <- readLines(file(file_path))

# Initialize an empty vector to store the DNA sequence lengths
sequence_lengths <- c()

# Read the input file line by line
for(line in input_file){
  if (grepl("^[AGCT]*$", line)) {
    # Add the length of the DNA sequence to the vector
    sequence_lengths <- c(sequence_lengths, nchar(line))
  }
}

# Close the input file
close(file(file_path))

# Create a histogram of the DNA sequence lengths
pdf("Filtered_read_lengths.pdf")
hist(sequence_lengths, xlab = "Size in bp", ylab = "Number of Reads", main = "Filtered Read length histogram")
dev.off()
