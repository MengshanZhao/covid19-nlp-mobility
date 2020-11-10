
library(data.table)
library(dplyr)
library(ggplot2)
library(tidyr)

rm(list=ls(all=TRUE))
score=read.csv("/Users/zhaomengshan/Desktop/724/Research/processing_data/sentiment_score.csv")

# Change the date variable
score$created_at <- strtrim(score$created_at, 10)


# Calculate the daily percentage 

percentage <-score %>%
  group_by(created_at) %>%
  summarise(
    positive = sum(vader_sentiment_labels == "positive"),
    negative = sum(vader_sentiment_labels == "negative"),
    total = n()
  )

percentage <-filter(percentage,total>=10)
percentage<-mutate(percentage, positive=positive/total)
percentage<-mutate(percentage, negative=negative/total)

# Finally, divide the date into two variables
date<-data.frame(weekday=substr(percentage$created_at, 1,4), date=substr(percentage$created_at,5,10))
percentage<-cbind(percentage,date)

write.csv(percentage,'sentiment_percentage.csv')

