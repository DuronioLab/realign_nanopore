#Get the arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the current working directory
wd <- getwd()

# Construct the path to the file using the current working directory
file_path <- file.path(wd, args[1])

filename <- args[1]

seq_name <- gsub("./", "", gsub(".gb", "", filename))

source_name <- paste(gsub(" ", "", Sys.getenv("USER")),".", format(Sys.Date(), format="%y-%m-%d"), sep = "")


genbank <- readr::read_tsv(file_path, col_names = FALSE)

saved <- data.frame(feature_type=character(),
                    start=integer(),
                    end=integer(),
                    direction=character(),
                    name=character())

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}
multis <- FALSE
for(i in which(grepl("/organism", genbank$X1))+1:which(grepl("ORIGIN", genbank$X1))){
  l <- strsplit(genbank$X1[i], " ")
  m <- lapply(l, function(x){x[!x ==""]})
  count <- 1
  
  if(!is.na(m[[1]][2])){
    if(substrRight(m[[1]][2], 1) == ","){
      multis <- TRUE
      count <- 2
      n <- strsplit(genbank$X1[i+1], " ")
      o <- lapply(n, function(x){x[!x ==""]})
      manyCDS <- paste(m[[1]][2],o[[1]][1], sep = "")
      numCDS <- lengths(regmatches(manyCDS, gregexpr(",", manyCDS))) + 1
      multiCDS <- data.frame(start = integer(),
                             end = integer())
      ranges <- regmatches(manyCDS, gregexpr("[[:digit:]]+", manyCDS))
      multiMax <- max(ranges[[1]])
      multiMin <- min(ranges[[1]])
    }
  }
  
  if(grepl("/", m[[1]][1]) == FALSE && grepl("/translation", genbank$X1[i-1]) == FALSE){
    temp_type <- m[[1]][1]
    ranges <- regmatches(m[[1]][2], gregexpr("[[:digit:]]+", m[[1]][2]))
    temp_start <- ranges[[1]][1]
    if(length(ranges[[1]]) == 1){
      tem_end <- ranges[[1]][1]
    }else{
      temp_end <- ranges[[1]][2]
    }
    if(grepl("complement", m[[1]][2])){
      temp_direction <- "-"
    }else{
      temp_direction <- "+"
    }
  }else{
    if(grepl("label=", m[[1]][1])){
      temp_name <- paste(gsub("/label=","",paste(m[[1]][], collapse = "_")), sep = "")
    }
  }
  
  # Save values to new line of growing dataframe if the next line is a new feature
  if(grepl("/", genbank$X1[i+count]) == FALSE){
    if(multis == TRUE){
      saved = rbind(saved, data.frame(feature_type="CDS",
                                      start=multiMin,
                                      end=multiMax,
                                      direction=temp_direction,
                                      name=temp_name))
      multis <- FALSE
      count <- 1
    }else{
      saved = rbind(saved, data.frame(feature_type=temp_type,
                                      start=temp_start,
                                      end=temp_end,
                                      direction=temp_direction,
                                      name=temp_name))
    }
  }
}


saved <- saved[complete.cases(saved), ]
saved <- saved[!duplicated(saved), ]
row.names(saved) <- 1:nrow(saved)

# Create an empty vector to store the modified values
modified_values <- c()

# Create a counter to keep track of the number of occurrences
counter <- 1

# Iterate through the rows of the column
for (i in 1:nrow(saved)) {
  # Get the current value in the column
  value <- saved[i, "name"]
  
  # Check if the value is an exact match for any other entry in the column
  matches <- sum(saved$name == value)
  
  # If there are multiple matches, add ".n" to the value
  if (matches > 1) {
    # Reset the counter for new values
    if (counter > matches) {
      counter <- 1
    }
    value <- paste0(value, ".", counter)
    counter <- counter + 1
  } else {
    # Reset the counter for new values
    counter <- 1
  }
  
  # Add the modified value to the vector
  modified_values <- c(modified_values, value)
}

# Replace the values in the column with the modified values
saved$name <- modified_values



## Generate new GTF file based on the data

gtf <- data.frame(seqname = character(),
                  source = character(),
                  feature = character(),
                  start = integer(),
                  stop = integer(),
                  score = character(),
                  direction = character(),
                  frame = integer(),
                  attributes = character())


for(i in 1:nrow(saved)){
  if(saved$feature_type[i] == "CDS"){
    attrib <- paste("gene_id \"",saved$name[i],"\"; transcript_id \"",saved$name[i],".1\"; gene_name \"",saved$name[i], "\";", sep = "")
    
    tmp_gtf <- data.frame(seqname = seq_name,
                          source = source_name,
                          feature = "CDS",
                          start = saved$start[i],
                          stop = saved$end[i],
                          score = ".",
                          direction = saved$direction[i],
                          frame = 0,
                          attributes = attrib)
    
    gtf <- rbind(gtf, tmp_gtf)
  }else if(any(grepl("UTR", saved[i,], ignore.case = TRUE))){
    attrib <- paste("gene_id \"",saved$name[i],"\"; transcript_id \"",saved$name[i],".1\"; gene_name \"",saved$name[i], "\";", sep = "")
    
    # Look for 3'UTRs
    if(any(grepl("3UTR", gsub("'","",saved[i,]), ignore.case = TRUE))){
      tmp_gtf <- data.frame(seqname = seq_name,
                            source = source_name,
                            feature = "3UTR",
                            start = saved$start[i],
                            stop = saved$end[i],
                            score = ".",
                            direction = saved$direction[i],
                            frame = 0,
                            attributes = attrib)
      gtf <- rbind(gtf, tmp_gtf)
      
      # Look for 5'UTRs  
    }else if(any(grepl("5UTR", gsub("'","",saved[i,]), ignore.case = TRUE))){
      tmp_gtf <- data.frame(seqname = seq_name,
                            source = source_name,
                            feature = "5UTR",
                            start = saved$start[i],
                            stop = saved$end[i],
                            score = ".",
                            direction = saved$direction[i],
                            frame = 0,
                            attributes = attrib)
      gtf <- rbind(gtf, tmp_gtf)
    }
  }else{
    # :P
  }
}




gtf_filename <- paste(seq_name, ".gtf", sep = "")
write.table(gtf, sep="\t", col.names = FALSE, row.names = FALSE, file = gtf_filename, quote = FALSE)


## Make FASTA file from Genbank

final_seq <- ""
fasta_filename <- paste(seq_name, ".fasta", sep = "")
fasta_header <- paste(">", seq_name, sep = "")
start_of_seq <- as.integer(which(grepl("ORIGIN", genbank$X1))+1)
end_of_seq <- as.integer(which(grepl("//", genbank$X1))[length(which(grepl("//", genbank$X1)))]-1)

for(i in start_of_seq:end_of_seq){
  temp_seq <- gsub("[[:digit:]]", "", gsub(" ", "", genbank$X1[i]))
  final_seq <- paste(final_seq, temp_seq, sep = "")
}

fasta_df <- rbind(data.frame(X1=fasta_header), data.frame(X1=final_seq))
write.table(fasta_df, sep="\t", col.names = FALSE, row.names = FALSE, file = fasta_filename, quote = FALSE)
