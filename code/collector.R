#!/usr/bin/Rscript

## 
# This collector uses the basis of the `ReliefWeb` 
# R package (https://github.com/luiscape/reliefweb). 
# 
# It collects data from the ReliefWeb API.
# 
## 

library(RCurl)
library(rjson)

ReliefWebLatest <- function(entity = NULL,
                     limit = NULL,
                     text.query = NULL,
                     query.field = NULL,
                     query.field.value = NULL,
                     add.fields = NULL,
                     from = NULL,
                     to = NULL,
                     debug = FALSE,
                     ver = "v1") {  # the v0 can be used for testing.
    
    #### Validation tests. ####
    # The validation tests before are useful for helping the user make a 
    # right query and understand why his query isn't working. 
    
    # Test if the query field has been provided.  
    if (is.null(query.field) == TRUE && is.null(text.query) == TRUE) { 
        stop("You have to either provide a `text.query' input or a `query.field` + `query.field.value` input.") 
    }
    
    if (is.null(query.field) == FALSE && is.null(query.field.value) == TRUE) { 
        stop("Please provide a value with a query field.") 
    }
    if (length(query.field) > 1) { stop('Please provide only one query field. Run rw.query.fields() if you are in doubt.') }
    
    if (is.null(limit) == FALSE && limit < 0 && tolower(limit) != "all") { 
        stop('Please provide an integer between 1 and 1000 or all.') 
    }
    
    if (is.null(limit) == FALSE && limit > 1000 && tolower(limit) != "all") { 
        stop('Please provide an integer between 1 and 1000 or all.') 
    }  # Increase the upper limit of the function.
    
    if (is.null(limit) == FALSE) { limit <- tolower(limit) }
    
    if (is.null(entity) == TRUE) { stop('Please provide an entity.') }
    
    all <- "all"
    
    
    #### Building the URL. ####

    # The entity url to be queried.
    if (is.null(entity) == FALSE) { entity.url <- paste('/', entity, sep = "") }
    
    # Offset URL -- for iterations.
    offset.url <- "?offset=0"  # starting at 0.
    
    # The limit to be used. 1000 is the maximum.
    if (is.null(limit) == TRUE) { limit.url <- paste("&", "limit=", 10, "&", sep = "")
                                  warning("The default limit for this querier is 10. \nIf you need more please provide a number           using \nthe 'limit' parameter.") }
    
    # for colleting `all` the database.
    if (is.null(limit) == FALSE) { limit.url <- paste("&", "limit=", 
                                                      ifelse(limit == "all", 1000, limit),
                                                      "&", sep = "") }
    
    # making sure the query is NULL 
    if (is.null(text.query) == TRUE) { text.query.url <- NULL }
    
    # for querying open text
    if (is.null(text.query) == FALSE) {
        text.query.url <- paste("query[value]=", 
                                text.query, 
                                sep = "")
        warning('In this version searching the open text field \nwill override whatever other field you have\nincluded the `query` paramenter. In further \nversions the open text field will allow you to\nfurther refine your search.')
    }
    
    # adding query fields.
    if (is.null(query.field) == FALSE) { query.field.url <- paste("query[value]=", 
                                                                  query.field, 
                                                                  ":", 
                                                                  query.field.value, 
                                                                  sep = "") }
    
    
    # cleaning the query field if nothing is provided. 
    if (is.null(query.field) == TRUE) { query.field.url <- NULL }
    
    # Function for building the right query when more than one field is provided.
    many.fields <- function(qf = NULL) { 
        
        all.fields.url.list <- list()
        for (i in 0:(length(qf) - 1)) { 
            field.url <- paste("fields[include][",i,"]=", qf[i + 1], sep = "")
            all.fields.url.list[i + 1] <- paste("&", field.url, sep = "")
        }
        all.fields.url <- paste(all.fields.url.list, collapse = "")
        return(all.fields.url)
    }
    
    if (is.null(add.fields) == FALSE) { add.fields.url <- many.fields(qf = add.fields) }
    
    ## Building URL for aquiring data. ##
    api.url <- "http://api.rwlabs.org/"
    version.url <- ver

    # taking our date.created. 
    # not necessary in version 1 of the API.
    if (entity != "country" | entity != "sources") { 
        sorting.url <- "&sort[]=date:desc" 
    }
    else { sorting.url <- "" }
    
    query.url <- paste(api.url,
                       version.url,
                       entity.url,
                       offset.url,
                       limit.url,
                       text.query.url,
                       query.field.url,
                       add.fields.url,
                       sorting.url, 
                       sep = "")
    
    

    #### Fetching the data. ####

    # Function for creating a data.frame.
    if (debug == TRUE) {
        x <- paste("The URL being queried is: ", query.url, sep = "")
        warning(x)
    }

    # Function to convert the resulting lits into rows in the data.frame
    FetchingFields <- function(df = NULL) {
        y <- 0
        it <- df$count
        if (length(it) > 0) {
                for (i in 1:it) {
                    x <- data.frame(df$data[[i]]$fields)
                    if ('iso3' %in% names(x) == FALSE) {  # hacky solution
                        y <- y + 1
                    }
                    else {
                        if (i == 1) { data <- x }
                        else {
                            common_cols <- intersect(colnames(data), colnames(x))
                            data <- rbind(
                                data[, common_cols], 
                                x[, common_cols]
                            )
                        }
                    }
                }
            if (debug == TRUE) { 
                print(paste(y, " record(s) didn't have iso3 codes.", sep = ""))
            } 
            data
        }
        else { }
    }
    
    # Function for creating iterations to go around 
    # the 1000-results limitation.
    RWIterations <- function(df = NULL) {
        
        final <- df
        
        limit <- ifelse(limit == "all", 1000, limit)
        total <- ceiling(count/limit)
        
        # Create progress bar.
        pb <- txtProgressBar(min = 0, max = total, style = 3)
            for (i in 2:total) {

                    setTxtProgressBar(pb, i)  # Updates progress bar.
                    
                    offset.url <- paste("?offset=", (limit * i) - 1000, sep = "")
                    
                    # updating URL in each iteration
                    query.url.it <- paste(api.url,
                                       version.url,
                                       entity.url,
                                       offset.url,
                                       limit.url,
                                       text.query.url,
                                       query.field.url,
                                       add.fields.url,
                                       sorting.url,
                                       sep = "")

                    if (debug == TRUE) {
                        print(paste("This is the it.url: ", query.url.it, sep = ""))
                        print(paste("From iteration number ", i, sep = ""))
                    }
                    
                    ## Error handling function for each iteration.
                    tryCatch(x <- fromJSON(getURLContent(query.url.it)), 
                             error = function(e) { 
                                 print("There was an error in the URL queried. Skipping ...")
                                 final <- final
                             }, 
                             finally = {
                                x <- FetchingFields(x)  # Cleaning fields.
                                if (entity == 'reports') { 
                                    if (is.null(to) == FALSE && 
                                            to != format(as.Date(x$created[1]), "%Y"))
                                    { break }  # adding a break function.
                                }
                                if (entity == 'disasters') { 
                                    if (is.null(to) == FALSE && 
                                            to != format(as.Date(x$created[1]), "%Y"))
                                    { break }  # adding a break function
                                }
                                final <- rbind(final, x)
                             }
                    )     
                }
        close(pb)
        return(final)
    }

    
    # Getting the count number for iterations later.
    count <- fromJSON(getURLContent(query.url))$totalCount
    
    # Querying the URL.
    query <- fromJSON(getURLContent(query.url))
    
    # Retrieving a data.frame
    data <- FetchingFields(query)
    
    # UI element.
    print(paste("Fetching ~", 
                ifelse(is.null(limit) == TRUE, 10, 
                       ifelse(identical(limit,all) == TRUE, count, limit)), 
                " records.", sep = ""))
    

    
    # Only run iterator if we are fetching "all" entries.
    if (identical(limit, all) == TRUE) { data <- RWIterations(data) }
    
    print("Done.")
    return(data)
}


GetLatestDisasters <- function() { 
    ReliefWebLatest(entity = 'disasters', 
                    limit = 'all',
                    text.query = "",
                    query.field = NULL,
                    query.field.value = NULL,
                    add.fields = c('id', 'primary_country.iso3', 'date.created', 'url'),
                    from = NULL,
                    to = 2014,
                    debug = FALSE,
                    ver = "v1") 
}

GetLatestReports <- function() { 
    ReliefWebLatest(entity = 'reports', 
                limit = 'all',
                text.query = "",
                query.field = NULL,
                query.field.value = NULL,
                add.fields = c('id', 'primary_country.iso3', 'date.created', 'url'),
                from = NULL,
                to = 2014,
                debug = FALSE,
                ver = "v1") 
}

GetAllDisasters <- function() { 
    ReliefWebLatest(entity = 'disasters', 
                    limit = 'all',
                    text.query = "",
                    query.field = NULL,
                    query.field.value = NULL,
                    add.fields = c('id', 'primary_country.iso3', 'date.created'),
                    from = NULL,
                    to = NULL,
                    debug = FALSE,
                    ver = "v1") 
}

GetAllReports <- function() { 
    ReliefWebLatest(entity = 'reports', 
                    limit = 'all',
                    text.query = "",
                    query.field = NULL,
                    query.field.value = NULL,
                    add.fields = c('id', 'primary_country.iso3', 'date.created', 'url'),
                    from = NULL,
                    to = NULL,
                    debug = FALSE,
                    ver = "v1") 
}

