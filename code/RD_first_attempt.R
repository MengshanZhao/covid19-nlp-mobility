rm(list=ls(all=TRUE))

library(data.table)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(lfe)

# import the datasets

policy<-read.csv("/Users/zhaomengshan/Desktop/724/data/Local-Policy-Responses-to-COVID-19.fin_ copy.csv")
mobility<-read.csv("/Users/zhaomengshan/Desktop/724/data/DL-COVID-19-master/DL-us-m50_index.csv")

# get rid of the national/state level results
mobility<-mobility[!(is.na(mobility$admin2) | mobility$admin2==""), ]

# Select the period 3.16-4.7
mobility<-select(mobility,3:4,21:43)
write.csv(mobility,'mobility_3_16_4_7.csv')

# Store the mobility file, change the column name to m/d/20, and the state name to shortcut, then reload it
mobility<-read.csv("/Users/zhaomengshan/Desktop/724/Research/processing_data/mobility_3_16_4_7.csv",check.names = FALSE)


# Create the lockdown date variable for each county
policy$lockdown <- ifelse(policy$dummysipstart == 0, policy$stsipstart, ifelse(policy$dummysipstart== 1 ,
                                                         policy$localsipstart,NA))

# select the useful columns
policy<-policy %>%
  select(lockdown, countyname,stname)

# Make a long table for mobility
mobility_longer<-pivot_longer(mobility, 3:25, names_to = "date", values_to = "mobility")

# merge the two datasets
df<-left_join(mobility_longer,policy , by = c('stname'='stname', 'countyname'='countyname'))
table1 <- table(df$stname)
prop.table(table1)
write.csv(df,'df_long.csv')
#Create two variables in Excel, before_1 is the date 1 day before the lockdown, and after_1
df<-read.csv("/Users/zhaomengshan/Desktop/724/Research/processing_data/df_long.csv")

#Create the object dummies: before, equal, after

df$equal <- ifelse(df$date == df$lockdown, "1","0")
df$before <- ifelse(df$date == df$Before_1, "1","0")
df$after <- ifelse(df$date == df$After_1, "1","0")
df$month <- strtrim(df$date, 1)

# Only keep the date where equal=1 or before=1 or after=1
df<-df %>% filter(equal == "1"|before== "1"|after== "1")

# Build the simple RDit model
df<-df %>%mutate(equal=as.numeric(equal),before=as.numeric(before),after=as.numeric(after))
model1<-felm(mobility ~ equal+after|month+countyname,data=df)
# not included before to use it as the base
summary(model1)

# Add control variables- sentiment/Weekends
sentiment<-read.csv("/Users/zhaomengshan/Desktop/724/Research/processing_data/sentiment_percentage.csv")
df_2<-left_join(df,sentiment , by = c('date'='date'))
model2 <- felm(mobility ~ equal+after+positive+negative+total+weekend|month+countyname, data=df_2)
summary(model2)

# Add control variables- number of death
covid<-read.csv("/Users/zhaomengshan/Desktop/covid-19-data-master/us-counties.csv")
covid$countyname <- paste0(covid$countyname, " County")

df_3<-left_join(df_2,covid , by = c('date'='date','stname'='stname', 'countyname'='countyname'))


model3 <- felm(mobility ~ equal+after+positive+negative+total+weekend+cases+deaths|month+countyname, 
                data=df_3)
summary(model3)
