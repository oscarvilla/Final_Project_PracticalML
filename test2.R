# Downloading data.
urlTraining <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
fileTraining <- "pml-training.csv"
urlTesting <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
fileTesting <- "pml-testing.csv"
# Import the data treating empty values as NA.
training <- read.csv(fileTraining, na.strings=c("NA",""), header=TRUE)
testing <- read.csv(fileTesting, na.strings=c("NA",""), header=TRUE)
colnames_train <- colnames(training)
colnames_test <- colnames(testing)