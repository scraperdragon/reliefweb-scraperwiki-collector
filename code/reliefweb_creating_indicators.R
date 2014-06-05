#!/usr/bin/Rscript

#### Function for creating a single table with the reports per contry. ####

ReliefwebCreateIndicators <- function(df = NULL, 
                                  begin = 2000, 
                                  end = 2014,
                                  entity = NULL, 
                                  focus = TRUE,
                                  latest = TRUE) {
    print('Creating indicators.')
    
    hdxdictionary <- load('code/data/hdxdictionary.rda')
    hdxdictionary <- hdx.dictionary
    
    # Standardizing the iso3 codes.
    df$iso3 <- toupper(df$iso3)
    
    # Standardizing dates. 
    if (entity == 'report') { df$created <- as.Date(df$created) }
    if (entity == 'disaster') { df$created <- as.Date(df$created) }
    
    # Creating a year facet. 
    if (entity == 'report') { df$year <- format(df$created, "%Y") }
    if (entity == 'disaster') { df$year <- format(df$created, "%Y") }
    
    
    if (focus == TRUE) { n.countries <- nrow(subset(hdxdictionary, hdxdictionary[7] == TRUE)) 
                         countries <- subset(hdxdictionary, hdxdictionary[7] == TRUE)}
    else { n.countries <- nrow(hdxdictionary) 
           countries <- hdxdictionary }
    
    # Create progress bar.
    pb <- txtProgressBar(min = 0, max = n.countries, style = 3)
    final.long <- data.frame()
    
    # If latest only iterate over 2014
    if (latest == TRUE) { begin <- 2014 }
    
    for (i in 1:n.countries) {  # for the number of focus countries in the master dictionary.
        setTxtProgressBar(pb, i)  # Updates progress bar.
        final.table <- data.frame()  # creating the a clean data.frame
        iso3.country <- as.character(countries$iso3c[i])
        
        for (i in begin:end) {  # iterations over the years. 
            year.subset <- subset(df, df$year == i & df$iso3 == iso3.country)
            year.it <- data.frame(nrow(year.subset))
            if (entity == 'report') { colnames(year.it)[1] <- 'n.reports' }
            if (entity == 'disaster') { colnames(year.it)[1] <- 'n.disasters' }
            year.it$year <- i
            year.it$iso3 <- iso3.country
            if (i == begin) { final.table <- year.it }
            else { final.table <- rbind(final.table, year.it) } 
        }
        if (i == 1) { final.long <- final.table }  # creating a single long table.
        else { final.long <- rbind(final.long, final.table) }
    }
    print('Done.')
    final.long
}