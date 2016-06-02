## Downloading data.
urlTraining <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
fileTraining <- "pml-training.csv"
urlTesting <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
fileTesting <- "pml-testing.csv"
## Import the data making empty values as NAs.
training <- read.csv(fileTraining, na.strings=c("NA",""), header=TRUE)
testing <- read.csv(fileTesting, na.strings=c("NA",""), header=TRUE)
## Checking identity names except the las colname
trainNames <- colnames(training)
testNames <- colnames(testing)
## Have the two data sets the same columns
all.equal(trainNames[-length(trainNames)], testNames[-length(testNames)])
## There are a lot of columns filled of NAs. Lets see how much
numNAsTraining <- apply(training, 2, function(x) sum(is.na(x)))
as.numeric(numNAsTraining)
numNAsTesting <- apply(testing, 2, function(x) sum(is.na(x)))
## All those columns have this proportion of cases as NAs
max(as.numeric(numNAsTraining)) / nrow(training)
## Will not try to fill it because of the proportion, and will remove it because they doesn't allow
## calculate predictions with the model if included as newdata.
trainingClean <- training[,(numNAsTraining == 0)]
testingClean <- testing[,(numNAsTesting == 0)]
## Let's check the number of NAs
sum(is.na(trainingClean))
sum(is.na(testingClean))
## I'll not take in account the first sevent columns, namely:
colnames(trainingClean)[1:7]
## Because they talk about row name, user name, time stamps in differents formats and the windows
## of observations
trainingClean <- trainingClean[, 8:ncol(trainingClean)]
testingClean <- testingClean[, 8:ncol(testingClean)]
## Checking both data sets have the same columns except the last one (class)
all.equal(names(trainingClean[,-ncol(trainingClean)]), names(testingClean[,-ncol(testingClean)]))
## So far we have the test set ready-tidy to apply machine learning
library(caret)
## Partitioning the data... 60% - 40%
inTrain2 <- createDataPartition(y = trainingClean$classe, times = 10, p = 0.60, list = FALSE)
training <- trainingClean[inTrain, ]
testing <- trainingClean[-inTrain, ]
## Checking partitioning did well done: it's the sum of the number of cases of the two new data equal
## to the number of cases of the original
nrow(training) + nrow(testing) == nrow(trainingClean)
## Because of the time that takes to run a random forest, I will to sparse the dataset in chunks aiming
## to run the random forest on each one and the stacking them together



## follow the instructions of lgreski
## on https://github.com/lgreski/datasciencectacontent/blob/master/markdown/pml-randomForestPerformance.md
## Set up training run for x / y syntax because model format performs poorly
x <- training[, -ncol(training)]
y <- training[, ncol(training)]
## Step 1: Configure parallel processing
library(parallel)
library(doParallel)
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)
## Step 2: Configure trainControl object
fitControl <- trainControl(method = "cv",
                           number = 10,
                           allowParallel = TRUE)
## Step 3: Develop training model
mdl1 <- train(x, y, method = "rf", trControl = fitControl, data = trainingClean)
## Step 4: De-register parallel processing cluster
stopCluster(cluster)
