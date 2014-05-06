#!/usr/bin/Rscript

library(RCurl)
library(rjson)
library(sqldf)


x <- fromJSON(getURL("http://api.rwlabs.org/v1/reports?offset=0&limit=1000&query[value]=&fields[include][0]=id&fields[include][1]=primary_country.iso3&fields[include][2]=date.created&sort[0]=date.created:desc"))

FetchingFields <- function(df = NULL) {
    for (i in 1:1000) {
        x <- data.frame(df$data[[i]]$fields)
        if (i == 1) { data <- x }
        else { 
            common_cols <- intersect(colnames(data), colnames(x))
            data <- rbind(
                data[, common_cols], 
                x[, common_cols]
            )
        }
    }
    data
}

# Fetching data. 
data <- FetchingFields(x)

# Storing the data in a SW database.
db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
dbWriteTable(db, "data", data, row.names = FALSE, append = TRUE) # for append
dbListFields(db, "data") 
NewData <- dbReadTable(db, "data") 
dbDisconnect(db)

