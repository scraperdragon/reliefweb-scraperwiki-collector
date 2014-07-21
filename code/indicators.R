#!/usr/bin/Rscript

### Creating indicators for ReliefWeb data. ###

source('code/collector.R')

cat('Collecting data.')
ReportData <- suppressWarnings(GetLatestReports())
DisasterData <- suppressWarnings(GetLatestDisasters())

# Collecting **all** data. 
# AllReportData <- GetAllReports()
# AllDisasterData <- GetAllDisasters()

cat('Generating metadata.')
source('code/generate_meta.R')
GenerateMeta()
# GenerateMeta(df = AllDisasterData)

cat('Storing the data in a SW database.')
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
    dbWriteTable(db, "_report_data", ReportData, row.names = FALSE, append = TRUE)
    dbWriteTable(db, "_disaster_data", DisasterData, row.names = FALSE, append = TRUE)
    dbWriteTable(db, "_scrape_meta", ScrapeMeta, row.names = FALSE, append = TRUE)
dbDisconnect(db)

cat('Creating indicators.')
source('code/reliefweb_creating_indicators.R')
ReportIndicators <- ReliefwebCreateIndicators(df = ReportData, 
                                              entity = 'report', 
                                              latest = TRUE)

DisasterIndicators <- ReliefwebCreateIndicators(df = DisasterData, 
                                                entity = 'disaster', 
                                                latest = TRUE)


cat('Creating the dataset table')
dsID <- 'reliefweb'
last_updated <- as.character(sort(ReportData$created)[1])
last_scraped <- ScrapeMeta$scrape_time
name <- 'ReliefWeb'
dtset <- data.frame(dsID, last_updated, last_scraped, name)

cat('Creating indicator table')
indID <- c('RW001', 'RW002')  # We have to create the indIDs for the indicators.
name <- c('Number of Reports', 'Number of Disasters')
units <- 'Count'  # Not sure what unit I should add here.
indic <- data.frame(indID, name, units)

cat('Creating the value table')
cat('... For reports')
reports <- ReportIndicators
reports$indID <- 'RW001'
colnames(reports)[1] <- 'value'
colnames(reports)[2] <- 'period'
colnames(reports)[3] <- 'region'
reports$region <- toupper(reports$region)
reports$dsID <- 'reliefweb'
reports$source <- 'ReliefWeb'

cat('... For disasters')
disasters <- DisasterIndicators
disasters$indID <- 'RW002'
colnames(disasters)[1] <- 'value'
colnames(disasters)[2] <- 'period'
colnames(disasters)[3] <- 'region'
disasters$region <- toupper(disasters$region)
disasters$dsID <- 'reliefweb'
disasters$source <- 'ReliefWeb'

# Getting both indicators into one table. 
zValue <- rbind(disasters, reports)

cat('Running the validation test.')
source('code/is_number.R')
zValue <- is_number(zValue)

# print(zValue)
cat('Store the 3 tables in a database.')
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")

    dbWriteTable(db, "dataset", dtset, row.names = FALSE, overwrite = TRUE)
    dbWriteTable(db, "indicator", indic, row.names = FALSE, overwrite = TRUE)

    # delete the entries from 2014
    cat('Updating entries from 2014.')
    dbGetQuery(db, "delete from value where period = 2014 
                   and indID = 'RW001'
                   and dsID = 'reliefweb'")

    dbGetQuery(db, "delete from value where period = 2014 
                   and indID = 'RW002'
                   and dsID = 'reliefweb'")

    dbWriteTable(db, "value", zValue, row.names = FALSE, append = TRUE)

    # for testing purposes
    # test <- dbReadTable(db, "value")
    
dbDisconnect(db)
cat('done')
