## 1. Downloading data.
urlTraining <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
fileTraining <- "pml-training.csv"
urlTesting <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
fileTesting <- "pml-testing.csv"
## 1.1. Import the data making empty values as NAs.
training <- read.csv(fileTraining, na.strings=c("NA",""), header=TRUE)
testing <- read.csv(fileTesting, na.strings=c("NA",""), header=TRUE)
## 1.2. Checking identity names except the las colname
trainNames <- colnames(training)
testNames <- colnames(testing)
## 1.3. Have the two data sets the same columns
all.equal(trainNames[-length(trainNames)], testNames[-length(testNames)])
## 2. There are a lot of columns filled of NAs. Lets see how much
numNAsTraining <- apply(training, 2, function(x) sum(is.na(x)))
table(as.numeric(numNAsTraining))
numNAsTesting <- apply(testing, 2, function(x) sum(is.na(x)))
## 2.1. All those columns have this proportion of cases as NAs
max(as.numeric(numNAsTraining)) / nrow(training)
## 2.2. Will not try to fill it because of the proportion, and will remove it because they doesn't allow
## calculate predictions with the model if included as newdata.
training <- training[,(numNAsTraining == 0)]
testing <- testing[,(numNAsTesting == 0)]
## 2.2.1 Let's check the number of NAs
sum(is.na(training))
sum(is.na(testing))
## 2.3. I'll not take in account the first sevent columns, namely:
colnames(training)[1:7]
## 2.3.1. Because they talk about row name, user name, time stamps in differents formats and the windows
## of observations
training <- training[, 8:ncol(training)]
testing <- testing[, 8:ncol(testing)]
## 2.3.2. Checking both data sets have the same columns except the last one (class)
all.equal(names(training[,-ncol(training)]), names(testing[,-ncol(testing)]))
## 3. So far we have the test set ready-tidy to start applying machine learning
library(caret)
## Partitioning the data... 60% - 20% - 20%%
set.seed(1981)
inTrain <- createDataPartition(training$classe, p = 0.60, list = FALSE)
trainingAll <- training[inTrain, ]
testingAll <- training[-inTrain, ]
## Checking partitioning did well done: it's the sum of the number of cases of the two new data equal
## to the number of cases of the original
nrow(trainingAll) + nrow(testingAll) == nrow(training)
rm(training)
## Now I gonna split the testingAll dataset into two blocks, one for testing and the another for validation
set.seed(1982)
inTrain <- createDataPartition(y = testingAll$classe, p = 0.50, list = FALSE)
testingTrained <- testingAll[inTrain, ]
validationtrained <- testingAll[-inTrain, ]
## Let's check
nrow(testingTrained) + nrow(validationtrained) == nrow(testingAll)
rm(testingAll)
## Because of the time that takes to run a random forest on a data set as big as this (I tryed it for 
## around 30 minutes with parallelizing for allow me to use three of the cores of a 
## Intel® Core™ i7-6500U CPU @ 2.50GHz × 4 with 8GB of RAM availables, but couldn't see the work ended)
dim(trainingAll)
## I will to split the dataset in 5 folds aiming to run the random forest and other models on each one
## and then stack them together with a random forest again
inTrain <- createFolds(y = trainingAll$classe, k = 5)
training1 <- trainingAll[inTrain$Fold1, ]
training2 <- trainingAll[inTrain$Fold2, ]
training3 <- trainingAll[inTrain$Fold3, ]
training4 <- trainingAll[inTrain$Fold4, ]
training5 <- trainingAll[inTrain$Fold5, ]
## Checking there are not repeated cases (rows): make a vector with all the elements of the lists (the
## cases and find out if there are duplicates among them)
DF <- rbind(as.numeric(inTrain$Fold1, inTrain$Fold2, inTrain$Fold3, inTrain$Fold4, inTrain$Fold5))
duplicated(DF)
## Checking no losses of rows
nrow(trainingAll) == nrow(training1) + nrow(training2) + nrow(training3) + nrow(training4) + nrow(training5)
rm(trainingAll)
## follow the instructions of lgreski aiming to speed up the process
## on https://github.com/lgreski/datasciencectacontent/blob/master/markdown/pml-randomForestPerformance.md
## Set up training run for x / y syntax because model format performs poorly
x1 <- training1[, -ncol(training1)]
y1 <- training1[, ncol(training1)]
x2 <- training2[, -ncol(training2)]
y2 <- training2[, ncol(training2)]
x3 <- training3[, -ncol(training3)]
y3 <- training3[, ncol(training3)]

## Step 1: Configure parallel processing
library(parallel)
library(doParallel)
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)
## Step 2: Configure trainControl object
fitControl <- trainControl(method = "cv",
                           number = 3,
                           allowParallel = TRUE)
## Step 3: Develop training model
mdl1 <- train(x1, y1, method = "rf", trControl = fitControl, data = training1)
mdl2 <- train(x2, y2, method = "rf", trControl = fitControl, data = training2)
mdl3 <- train(x3, y3, method = "rf", trControl = fitControl, data = training3)
library(e1071)
mdl4 <- svm(classe ~ ., data = training4)
## Step 4: De-register parallel processing cluster
stopCluster(cluster)
## The stacking model is on the Q4 q2