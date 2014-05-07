#!/usr/bin/Rscript

### Creating indicators for ReliefWeb data. ###

source('code/collector.R')

# Collecting data.
ReportData <- suppressWarnings(GetLatestReports())
DisasterData <- suppressWarnings(GetLatestDisasters())

# Collecting **all** data. 
# AllReportData <- GetAllReports()
# AllDisasterData <- GetAllDisasters()

# Generating metadata.
source('code/generate_meta.R')
GenerateMeta()
# GenerateMeta(df = AllDisasterData)

# Storing the data in a SW database.
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
    dbWriteTable(db, "report_data", ReportData, row.names = FALSE, append = TRUE)
    dbWriteTable(db, "disaster_data", DisasterData, row.names = FALSE, append = TRUE)
    dbWriteTable(db, "scrape_meta", ScrapeMeta, row.names = FALSE, append = TRUE)
dbDisconnect(db)

# Creating indicators.
source('code/reliefweb_creating_indicators.R')
ReportIndicators <- ReliefwebCreateIndicators(df = ReportData, 
                                              entity = 'report', 
                                              latest = TRUE)

DisasterIndicators <- ReliefwebCreateIndicators(df = DisasterData, 
                                                entity = 'disaster', 
                                                latest = TRUE)


## Creating the dataset table ## 
dsID <- 'reliefweb'
last_updated <- as.character(sort(ReportData$changed)[1])
last_scraped <- ScrapeMeta$scrape_time
name <- 'ReliefWeb'
dtset <- data.frame(dsID, last_updated, last_scraped, name)

## Creating indicator table ## 
indID <- c('RW001', 'RW002')  # We have to create the indIDs for the indicators.
name <- c('Number of Reports', 'Number of Disasters')
units <- 'Count'  # Not sure what unit I should add here.
indic <- data.frame(indID, name, units)

## Creating the value table ##
# For reports
reports <- ReportIndicators
reports$indID <- 'RW001'
colnames(reports)[1] <- 'value'
colnames(reports)[2] <- 'period'
colnames(reports)[3] <- 'region'
reports$dsID <- 'reliefweb'
reports$source <- 'ReliefWeb'

# For disasters
disasters <- DisasterIndicators
disasters$indID <- 'RW002'
colnames(disasters)[1] <- 'value'
colnames(disasters)[2] <- 'period'
colnames(disasters)[3] <- 'region'
disasters$dsID <- 'reliefweb'
disasters$source <- 'ReliefWeb'

# Getting both indicators into one table. 
zValue <- rbind(disasters, reports)

# Running the validation test. 
source('code/is_number.R')
zValue <- is_number(zValue)

# Store the 3 tables in a database.
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")

    dbWriteTable(db, "dataset", dtset, row.names = FALSE, overwrite = TRUE)
    dbWriteTable(db, "indicator", indic, row.names = FALSE, overwrite = TRUE)
<<<<<<< HEAD

    # delete the entries from 2014
    dbSendQuery(db, "delete from value where period = 2014 
                    and indID = 'RW001'
                    and dsID = 'reliefweb'")

    dbSendQuery(db, "delete from value where period = 2014 
                    and indID = 'RW002'
                    and dsID = 'reliefweb'")
    
    dbWriteTable(db, "value", zValue, row.names = FALSE, append = TRUE)
=======
    dbWriteTable(db, "value", zValue, row.names = FALSE, overwrite = TRUE)
    # dbListFields(db, "data")

dbDisconnect(db)

db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
    test <- dbReadTable(db, "value")
dbDisconnect(db)
>>>>>>> a038013e41dc5c2f7be3a3a7bc31c87e7796573b

    # for testing purposes
    # test <- dbReadTable(db, "value")
    
dbDisconnect(db)
