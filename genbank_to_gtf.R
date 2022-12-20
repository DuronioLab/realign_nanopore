#Get the arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the current working directory
wd <- getwd()

# Construct the path to the file using the current working directory
file_path <- file.path(wd, args[1])

filename <- args[1]

seq_name <- gsub("./", "", gsub(".gb", "", filename))

source_name <- paste(gsub(" ", "", Sys.getenv("USERNAME")),".", format(Sys.Date(), format="%y-%m-%d"), sep = "")


genbank <- readr::read_tsv(file_path, col_names = FALSE)

saved <- data.frame(feature_type=character(),
                    start=integer(),
                    end=integer(),
                    direction=character(),
                    name=character())

for(i in which(grepl("/organism", genbank$X1))+1:which(grepl("ORIGIN", genbank$X1))){
  l <- strsplit(genbank$X1[i], " ")
  m <- lapply(l, function(x){x[!x ==""]})
  
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
      temp_name <- paste(gsub("/label=","",paste(m[[1]][], collapse = "_")), i, sep = "")
    }
  }
  
  # Save values to new line of growing dataframe if the next line is a new feature
  if(grepl("/", genbank$X1[i+1]) == FALSE){
    saved = rbind(saved, data.frame(feature_type=temp_type,
                                    start=temp_start,
                                    end=temp_end,
                                    direction=temp_direction,
                                    name=temp_name))
    
  }
}


saved <- saved[complete.cases(saved), ]
saved <- saved[!duplicated(saved), ]
row.names(saved) <- 1:nrow(saved)

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
  }else if(any(grepl("UTR", saved[28,], ignore.case = TRUE))){
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

gtf_filename <- paste(seq_name, "_annotations.gtf", sep = "")
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
