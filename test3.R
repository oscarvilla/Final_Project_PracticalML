## 1. Downloading data.
urlTraining <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
fileTraining <- "pml-training.csv"
urlTesting <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
fileTesting <- "pml-testing.csv"
## 1.1. Import the data making empty values as NAs.
training <- read.csv(fileTraining, na.strings=c("NA",""), header=TRUE)
testing <- read.csv(fileTesting, na.strings=c("NA",""), header=TRUE)
## Cleaning
rm(list = c("urlTesting", "urlTraining"))
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
## Cleaning
rm(list = c("numNAsTesting", "numNAsTraining", "testNames", "trainNames"))
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
## Now I gonna split the testingAll dataset into two blocks, one for testing and the another for 
## validation
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
## rpart as method yields just 0.5073 of accuracy, not enougth
## lda as method yields just 0.7 of accuracy, not enougth
## svm as method yields a accuracy of 0.89. It's not so bad

dim(trainingAll)
## I will to split the dataset in 5 folds aiming to run the random forest and other models on each one
## and then stack them together with a random forest again
set.seed(1983)
inTrain <- createFolds(y = trainingAll$classe, k = 4)
training1 <- trainingAll[inTrain$Fold1, ]
training2 <- trainingAll[inTrain$Fold2, ]
training3 <- trainingAll[inTrain$Fold3, ]
training4 <- trainingAll[inTrain$Fold4, ]
## Checking there are not repeated cases (rows): make a vector with all the elements of the lists (the
## cases and find out if there are duplicates among them)
DF <- rbind(as.numeric(inTrain$Fold1, inTrain$Fold2, inTrain$Fold3, inTrain$Fold4))
duplicated(DF)
rm(DF)
## Checking no losses of rows
nrow(trainingAll) == nrow(training1) + nrow(training2) + nrow(training3) + nrow(training4)
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
x4 <- training4[, -ncol(training4)]
y4 <- training4[, ncol(training4)]
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
set.seed(1984)
mdl1 <- train(x1, y1, method = "rf", trControl = fitControl, data = training1)
mdl2 <- train(x2, y2, method = "rf", trControl = fitControl, data = training2)
mdl3 <- train(x3, y3, method = "rf", trControl = fitControl, data = training3)
mdl4 <- train(x4, y4, method = "rf", trControl = fitControl, data = training4)
## Step 4: De-register parallel processing cluster
stopCluster(cluster)
rm(list = c("x1", "x2", "x3", "x4", "y1", "y2", "y3", "y4"))
## checking metrics with confusionMatrix
pred1 <- predict(mdl1, testingTrained)
pred2 <- predict(mdl2, testingTrained)
pred3 <- predict(mdl3, testingTrained)
pred4 <- predict(mdl4, testingTrained)
acc <- rbind(mdl1 = confusionMatrix(pred1, testingTrained$classe)$overall, 
             mdl2 = confusionMatrix(pred2, testingTrained$classe)$overall, 
             mdl3 = confusionMatrix(pred3, testingTrained$classe)$overall, 
             mdl4 = confusionMatrix(pred4, testingTrained$classe)$overall)
sens <- rbind(mdl1 = t(confusionMatrix(pred1, testingTrained$classe)$byClass)[1,], 
                  mdl2 = t(confusionMatrix(pred2, testingTrained$classe)$byClass)[1,], 
                  mdl3 = t(confusionMatrix(pred3, testingTrained$classe)$byClass)[1,], 
                  mdl4 = t(confusionMatrix(pred4, testingTrained$classe)$byClass)[1,])
acc <- rbind(mdl1 = t(confusionMatrix(pred1, testingTrained$classe)$byClass)[2,], 
              mdl2 = t(confusionMatrix(pred2, testingTrained$classe)$byClass)[2,], 
              mdl3 = t(confusionMatrix(pred3, testingTrained$classe)$byClass)[2,], 
              mdl4 = t(confusionMatrix(pred4, testingTrained$classe)$byClass)[2,])
sensAvg <- t(data.frame(allMdlsAvg = colMeans(sens)))
accAvg <- t(data.frame(allModelsAvg = colMeans(acc)))
## Stacking
myStack <- data.frame(mdl1 = pred1, 
                      mdl2 = pred2, 
                      mdl3 = pred3, 
                      mdl4 = pred4, 
                      response = testingTrained$classe)
## Cleaning 
rm(list = c("training1", "training2", "training3", "training4"))
rm(list = c("mdl1", "mdl2", "mdl3", "mdl4"))
rm(list = c("pred1", "pred2", "pred3", "pred4"))
## Parallelizing again
library(parallel)
library(doParallel)
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)
fitControl <- trainControl(method = "cv",
                           number = 3,
                           allowParallel = TRUE)
x <- myStack[, -ncol(myStack)]
y <- myStack[, ncol(myStack)]
mdl <- train(x, y, method = "rf", trControl = fitControl, data = myStack)
stopCluster(cluster)
## Measuring accuracy
pred <- predict(mdl, myStack)
ppalMetrics <- t(confusionMatrix(pred, myStack$response)$byClass)[1:2,]
## Comparing accuracies
ppalMetrics; sensAvg; accAvg
performance <- data.frame(accGain = ppalMetrics[1, ] - sensAvg, 
                          sensGain = ppalMetrics[2, ] - accAvg)
performance
## Cleaning
rm(list = c("accAvg", "sensAvg", "performance", "sens", "acc", "ppalMetrics", "x", "y"))
## Testing on independent test set: validationtrained
## We can see that even the stacking doesn't increase the perform significantly. So, we can just
## create a model based on random forest with a dataset of the same number of cases and expect to
## give back a similar metrics, namely: accuracy and sensitivity
## I made the model training it on the validation set. It could be on whatever of the 4 folds
## previously generated, but the dataset with better metrics was the validation one, so that
## I choose to train the model over this one.
cluster <- makeCluster(detectCores() - 1)
registerDoParallel(cluster)
fitControl <- trainControl(method = "cv",
                           number = 3,
                           allowParallel = TRUE)
x <- validationtrained[, -ncol(validationtrained)]
y <- validationtrained[, ncol(validationtrained)]
mdlFinal <- train(x, y, method = "rf", trControl = fitControl, data = validationtrained)
stopCluster(cluster)
predFinal <- predict(mdlFinal, validationtrained)
confusionMatrix(predFinal, validationtrained$classe)
## The perfomance is awesome 100% in all the five classes
## So, let's predict with the model on the quiz set, namely: in this case testing
quizResponse <- predQuiz <- predict(mdlFinal, testing)
## I got 20/20: Perfect
