#Get the arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the current working directory
wd <- getwd()

# Construct the path to the file using the current working directory
file_path <- file.path(wd, args[1])

# Read the input file
input_file <- file(file_path)
data <- read.table(input_file, sep = "\t")
data2 <- as.data.frame(data)
data3 <- data.frame()

#close(input_file)

# Initialize an empty dataframe to hold the selected rows
selected_rows <- data.frame()

# Initialize a counter to keep track of how many rows have been added to the new dataframe
count <- 0

# Iterate through the rows of the dataframe
for (i in 1:nrow(data2)) {
  # Check if the current row contains a ">" character
  if (grepl(">", data2[i,1])) {
    # If so, add the current row and the next row to the new dataframe
    selected_rows <- rbind(selected_rows, data2[i,], data2[i+1,])
    # Increment the counter
    count <- count + 1
  }
  
  # Stop iterating once 36 rows have been added to the new dataframe
  if (count == 36) {
    break
  }
}

# Split each line into lines of at most 50 characters
for (i in 1:nrow(selected_rows)) {
  data3[i,1] <- substr(selected_rows[i,1],1,50)
}


dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("BiocManager", quietly=TRUE)){
  install.packages("BiocManager", lib = Sys.getenv("R_LIBS_USER"), quiet=TRUE, repos = "https://cran.rstudio.com/")
  }

BiocManager::install("msa", update = FALSE, lib = Sys.getenv("R_LIBS_USER"), quiet=TRUE, ask=FALSE)
#BiocManager::install("msa", update = FALSE, lib = Sys.getenv("R_LIBS_USER"), force=TRUE)

library(msa, quiet=TRUE)

write.table(data3, file = "shortened.fasta", row.names = FALSE, col.names = FALSE, quote = FALSE)
myseq <- readDNAStringSet("./shortened.fasta")

myalign <- msa(myseq)

# define a function to print some output to the console
print_output <- function() {
  print(myalign, show="alignment", halfNrow=45)
}

# use the sink() function to redirect the output to a file
sink("Restart_Alignment.txt")

# call the function to print the output
print_output()

# use the sink() function to stop redirecting the output
sink()
