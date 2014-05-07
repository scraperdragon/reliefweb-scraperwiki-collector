#!/usr/bin/Rscript

# Adding a scrape id and a time stamp.
GenerateMeta <- function(df = c(ReportData, DisasterData)) { 
    
    # Metadata from the scrape.
    scrape_id <- ceiling(runif(1, 100000, 999999))
    scrape_time <- as.character(Sys.time())
    
    # Adding the metadata to the original data.
    ReportData$scrape_id <<- scrape_id
    DisasterData$scrape_id <<- scrape_id
#     AllDisasterData$scrape_id <<- scrape_id
    
    # Exporting the metadata table.
    ScrapeMeta <<- data.frame(scrape_id, scrape_time)
}