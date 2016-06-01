## loading training data
pml.training <- read.csv("~/Documents/Practical Machine Learning/Final_Project_PracticalML/pml-training.csv", 
                         header=FALSE)
## Counting the number of NA's on each column
numNAs <- apply(pml.training, 2, function(x) sum(is.na(x)))
## Teher area lot of columns full of NA's. Every one of them have 19216 NA's; just
19623 - 19216
(19623 - 19216) / 19623
## It's a pretty little percentage of cases, so I'll erase those columns
library(data.table)
DT <- as.data.table(pml.training)
