---
  title: "Artemas Wang"
author: "Artemas Wang"
date: "1/18/2021"
output: html_document
---
  
  ```{r -}
```

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r - loading in libraries}
library(tidyverse)
library(data.table)
library(readxl)
```

```{r - Only needs to be run once- converting files from xlsx to csv}

# Create a vector of Excel files to read
files.to.read <- list.files(path = "/Users/artemaswang/Desktop/Test", pattern="xlsx", full.names = TRUE)

# First function reads all the xlsx workbooks, second function creates sheets from all workbooks.
all_files_csv <- lapply(files.to.read, function(x)
{
  sheets <- excel_sheets(x)
  lapply(sheets, function(y)
  {
    df = read_excel(x, sheet=y)
    write.csv(df, paste0(tools::file_path_sans_ext(basename(x)), y, '.csv'),
              row.names=FALSE)
  })
})

# Reading in as csv keeps data integrity within the sheets
files.to.read <- list.files(path = "/Users/artemaswang/Desktop/Test", pattern="csv", full.names = TRUE)

all_files <- list2env(lapply(setNames(files.to.read, make.names(gsub(".csv", "", files.to.read))), read.csv), envir = .GlobalEnv)
```


```{r - reading in data}
source1_a_day <- fread(paste0("SOURCE 1 PLATFORM A_input_Day.csv"), header = T, stringsAsFactors = F, data.table = T)
source1_a_hour <- fread(paste0("SOURCE 1 PLATFORM A_input_Hour.csv"), header = T, stringsAsFactors = F, data.table = T)
source1_b_day <- fread(paste0("SOURCE 1 PLATFORM B_input_Day.csv"), header = T, stringsAsFactors = F, data.table = T)
source1_b_hour <- fread(paste0("SOURCE 1 PLATFORM B_input_Hour.csv"), header = T, stringsAsFactors = F, data.table = T)
source1_reach <- fread(paste0("SOURCE 1 REACH.csv"), header = T, stringsAsFactors = F, data.table = T)
source2_hour <- fread(paste0("SOURCE 2_input_Summary_Day_Hour.csv"), header = T, stringsAsFactors = F, data.table = T)
source2_day <- fread(paste0("SOURCE 2_input_Summary_Day.csv"), header = T, stringsAsFactors = F, data.table = T)
source2_summary <- fread(paste0("SOURCE 2_input_Summary.csv"), header = T, stringsAsFactors = F, data.table = T)
```

```{r - understanding data}
str(source1_a_day)
source1_reach
```

```{r - indexing and tidying data for the variables we need for output}
source1_a_day <- source1_a_day[3:11,] 
names(source1_a_day) <- source1_a_day %>% slice(1) %>% unlist()
source1_a_day <- source1_a_day[2:9,] 

source1_a_hour <- source1_a_hour[3:28,]
names(source1_a_hour) <- source1_a_hour %>% slice(1) %>% unlist()
source1_a_hour <- source1_a_hour[2:26,] 

source1_b_day <- source1_b_day[3:11,]
names(source1_b_day) <- source1_b_day %>% slice(1) %>% unlist()
source1_b_day <- source1_b_day[2:9,] 

source1_b_hour <- source1_b_hour[3:28,]
names(source1_b_hour) <- source1_b_hour %>% slice(1) %>% unlist()
source1_b_hour <- source1_b_hour[2:26,] 

source1_reach <- source1_reach %>% select(`PLATFORM A Only Unique Households`, `PLATFORM B Only Unique Households`) 

source2_hour <- source2_hour # nothing needs indexing

source2_day <- source2_day[1:8,]
source2_summary <- source2_summary[1,]

```


```{r - merging data sets (day)}

# merging source 1a and 1b
first_merge <- merge(source1_a_day, source1_b_day, by.x = "Display By", by.y = "Display By")

# renaming source 2 for merge
source2_day$`Day of Week` <- gsub("Sun", "Sunday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Mon", "Monday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Tue", "Tuesday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Wed", "Wednesday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Thu", "Thursday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Fri", "Friday", source2_day$`Day of Week`)
source2_day$`Day of Week` <- gsub("Sat", "Saturday", source2_day$`Day of Week`)

# merging source 1 and 2
final_day <- merge(first_merge, source2_day, by.x = "Display By", by.y = "Day of Week")

# summing total impressions from source 1
Total_Impressions <- final_day %>% select(`Display By`, Impressions.x, Impressions.y, Impressions)

# changing data type from characters to numerics
Total_Impressions[,2:4] <- lapply(Total_Impressions[,2:4], function(x) as.numeric(gsub(",", "", x)))

# totaling all impressions
Total_Impressions$`Total Impressions` <- apply(Total_Impressions[,2:4], 1, sum) 

# selecting final columns
Total_Impressions <- Total_Impressions %>% rename("Day of Week" = "Display By")
Final_Day_of_Week <- Total_Impressions %>% select(`Day of Week`, `Total Impressions`)

# sorting 
Final_Day_of_Week$`Day of Week` <- factor(Final_Day_of_Week$`Day of Week`, levels= c("Monday", 
                                                                                     "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Total"))
Final_Day_of_Week <- Final_Day_of_Week[order(Final_Day_of_Week$`Day of Week`), ]
Final_Day_of_Week
```

```{r - merging data sets (dayparts/hour)}

# merging source 1a and 1b
hour_merge <- merge(source1_a_hour, source1_b_hour, by.x = "Display By", by.y = "Display By")

# merging source 1 and 2
final_hour <- merge(hour_merge, source2_hour, by.x = "Display By", by.y = "Time of Day Total")

# summing total impressions from source 1
Hour_Impressions <- final_hour %>% select(`Display By`, Impressions.x, Impressions.y, Impressions)

# creating the parts of the day
as.factor(Hour_Impressions$`Display By`)
Hour_Impressions$DayPart <- ifelse(Hour_Impressions$`Display By` == "9:00 AM" |
                                     Hour_Impressions$`Display By` == "10:00 AM" | 
                                     Hour_Impressions$`Display By` =="11:00 AM" | 
                                     Hour_Impressions$`Display By` =="12:00 PM" | 
                                     Hour_Impressions$`Display By` =="1:00 PM" | 
                                     Hour_Impressions$`Display By` =="2:00 PM" |
                                     Hour_Impressions$`Display By` =="3:00 PM", "Daytime - 9AM-4PM", 
                                   ifelse(Hour_Impressions$`Display By` == "4:00PM" | 
                                            Hour_Impressions$`Display By` == "5:00 PM", "Early Fringe - 4PM-6PM",
                                          ifelse(Hour_Impressions$`Display By` == "6:00 AM" | 
                                                   Hour_Impressions$`Display By` == "7:00 AM" | 
                                                   Hour_Impressions$`Display By` == "8:00 AM", "Early Morning - 6AM-9AM",
                                                 ifelse(Hour_Impressions$`Display By` == "11:00 PM", "Late Fringe - 11PM-12AM",
                                                        ifelse(Hour_Impressions$`Display By` == "12:00 AM" | 
                                                                 Hour_Impressions$`Display By` =="1:00 AM" | 
                                                                 Hour_Impressions$`Display By` =="2:00 AM" | 
                                                                 Hour_Impressions$`Display By` =="3:00 AM" | 
                                                                 Hour_Impressions$`Display By` == "4:00 AM" |
                                                                 Hour_Impressions$`Display By` =="5:00 AM", "Overnight - Midnight-6AM", 
                                                               ifelse(Hour_Impressions$`Display By` == "8:00 PM" | 
                                                                        Hour_Impressions$`Display By` == "9:00 PM" | 
                                                                        Hour_Impressions$`Display By` == "10:00 PM", "Prime - 8PM-11PM",
                                                                      ifelse(Hour_Impressions$`Display By` == "Total", "Total", "Prime Access - 6PM-8PM")))))))

# changing data type from characters to numerics
Hour_Impressions[,2:4] <- lapply(Hour_Impressions[,2:4], function(x) as.numeric(gsub(",", "", x)))

# Totaling all impressions
Hour_Impressions$`Total Impressions` <- apply(Hour_Impressions[,2:4], 1, sum) 

# Final tidying

Final_Hour_Impressions <- Hour_Impressions %>% select(DayPart, `Total Impressions`)
Final_Hour_Impressions <- aggregate(`Total Impressions` ~ DayPart, data = Final_Hour_Impressions, sum)

Final_DayPart <- Final_Hour_Impressions
Final_DayPart
```

```{r - creating total reach}
str(source1_reach)
source1_reach <- gsub(",","",source1_reach)
source2_summary <- gsub(",","",source2_summary[,8])
Total_Reach <- sum(as.numeric(as.character(source1_reach)))
Source_2_total <- sum(as.numeric(as.character(source2_summary)))

source_1_2 <- merge(Total_Reach, Source_2_total)
Total_Reach <- sum(source_1_2$x, source_1_2$y)

Total_Reach$Day <- c("Total")
Final_Reach <- as.data.frame(Total_Reach)
Final_Reach <- Final_Reach %>% rename("Total Reach" = X1794385)

Final_Reach
```

```{r - creating final view}
Final_Impressions <- Final_Hour_Impressions %>% filter(DayPart == "Total")
Final_Summary <- merge(Final_Impressions, Final_Reach, by.x = "DayPart", by.y = "Day")
Final_Summary <- Final_Summary %>% rename("Cut" = DayPart)
Final_Summary
```

```{r - writing to xlsx}
library(openxlsx)
list_of_datasets <- list("Summary" = Final_Summary, "Day of Week" = Final_Day_of_Week, "Day Parts" = Final_DayPart)

write.xlsx(list_of_datasets, "Artemas Wang Final.xlsx")
```





