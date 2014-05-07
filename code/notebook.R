#!/usr/bin/Rscript

library(RCurl)
library(rjson)
library(sqldf)
library(lubridate)
library(ggplot2)


source('code/collector.R')
# Getting **all** data 
AllReportData <- suppressWarnings(GetAllReports())
AllDisasterData <- suppressWarnings(GetAllDisasters())

# Getting latest data. 
ReportData <- GetLatestReports()
DisasterData <- GetLatestDisasters()

# Storing the data in a SW database.
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
    dbWriteTable(db, "data", data, row.names = FALSE, append = TRUE) # for append
    dbListFields(db, "data") 
    NewData <- dbReadTable(db, "data") 
dbDisconnect(db)



## Quick look to see if it is working fine ## 
library(ggplot2)
ggplot(test) + theme_bw() + 
    geom_line(aes(year, n.disasters), stat = 'identity', size = 1.3, color = "#0988bb") +
    geom_area(aes(year, n.disasters), stat = 'identity', size = 1.3, 
              fill = "#0988bb", 
              alpha = 0.3) +
    facet_wrap( ~ iso3)



# Testing the database has stored the data properly. 
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
dbReadTable(db, "value")
dbDisconnect(db)



HistoricalData <- subset(DisasterIndicators, DisasterIndicators$year != 2014)


# Store the 3 tables in a database.
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
#     dbWriteTable(db, "dataset", dtset, row.names = FALSE, overwrite = TRUE)
#     dbWriteTable(db, "indicator", indic, row.names = FALSE, overwrite = TRUE)
    dbWriteTable(db, "value", HistoricalData, row.names = FALSE, overwrite = TRUE)
dbDisconnect(db)

# Creating indicators from > 2014 disasters
source('reliefweb_creating_indicators.R')
DisHistoricalData <- ReliefwebCreateIndicators(AllDisasterData, entity = 'disaster', begin = 1981, end = 2013, latest = FALSE)


x1 <- fromJSON(getURL('http://api.rwlabs.org/v1/reports?offset=0&limit=1000&query[value]=&fields[include][0]=id&fields[include][1]=primary_country.iso3&fields[include][2]=date.changed&fields[include][3]=url&sort[]=date:desc'))



#                     print(to == format(as.Date(x$changed[1]), "%Y"))
#                     print(format(as.Date(x$changed[1]), "%Y"))
if  ((to == format(as.Date(x$changed[1]), "%Y")) 
     == FALSE) { break }
