#' Get Total Number of PubMed Articles for a Search Term
#'
#' This function queries the NCBI E-utilities API to retrieve the total number of 
#' PubMed articles that match a given search term or R package name.
#'
#' @param package_name A character string representing the search term (e.g., an R package name).
#' @param api_key Optional. A character string with an NCBI API key. If not supplied,
#' it will attempt to use the option \code{getOption("pubmed.api_key")}.
#'
#' @return An integer representing the total number of PubMed articles matching the search term, 
#' or \code{NA} if the request fails.
#'
#' @examples
#' \dontrun{
#' get_pubmed_count("ggplot2")
#' }
#'
#' @import curl
#' @importFrom jsonlite fromJSON
#' @export
get_pubmed_count <- function(package_name, api_key = getOption("pubmed.api_key", NULL)) {
  query <- URLencode(package_name)
  full_url <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
                     "?db=pubmed&term=", query, "&retmode=json")
  
  if (!is.null(api_key)) {
    full_url <- paste0(full_url, "&api_key=", api_key)
  }
  
  h <- new_handle()
  con <- tryCatch(curl(full_url, handle = h), error = function(e) return(NULL))
  if (is.null(con)) return(NA)
  
  res <- tryCatch(readLines(con, warn = FALSE), error = function(e) return(NULL))
  close(con)
  
  if (is.null(res)) return(NA)
  
  data <- tryCatch(jsonlite::fromJSON(paste(res, collapse = "")), error = function(e) return(NULL))
  if (is.null(data)) {
    message("No articles found on pubmed for ", package_name)
    return(NA)
  } 

  count <- as.numeric(data$esearchresult$count)
  return(count)
}

#' Get Annual PubMed Article Counts for a Search Term
#'
#' This function queries the NCBI E-utilities API to retrieve the number of PubMed articles
#' published each year over a specified number of past years for a given search term or package name.
#'
#' @param package_name A character string representing the search term (e.g., an R package name).
#' @param years_back An integer specifying how many years back to query. Defaults to 10.
#' @param api_key Optional. A character string with an NCBI API key. If not supplied,
#' it will attempt to use the option \code{getOption("pubmed.api_key")}.
#'
#' @return A data frame with two columns:
#' \describe{
#'   \item{Year}{The publication year (integer).}
#'   \item{Count}{The number of articles published in that year (integer).}
#' }
#' Returns an empty data frame if no valid data is retrieved.
#'
#' @examples
#' \dontrun{
#' get_pubmed_by_year("ggplot2", years_back = 5)
#' }
#'
#' @import curl
#' @import xml2
#' @export
get_pubmed_by_year <- function(package_name, years_back = 10, api_key = getOption("pubmed.api_key", NULL)) {
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  start_year <- current_year - years_back
  year_counts <- integer()
  
  for (year in start_year:current_year) {
    count <- tryCatch({
      query <- URLencode(paste0(package_name, " AND ", year, "[dp]"))
      esearch_url <- paste0(
        "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
        "?db=pubmed&term=", query,
        "&retmode=xml"
      )
      if (!is.null(api_key)) {
        esearch_url <- paste0(esearch_url, "&api_key=", api_key)
      }
      
      xml_data <- xml2::read_xml(curl::curl(esearch_url))
      as.integer(xml2::xml_text(xml2::xml_find_first(xml_data, "//Count")))
    }, error = function(e) {
      message("No articles found on pubmed for ", package_name)
      return(NA)
    })
    
    year_counts[as.character(year)] <- count
  }
  
  valid <- !is.na(year_counts)
  if (!any(valid)) {
    return(data.frame(Year = integer(), Count = integer(), stringsAsFactors = FALSE))
  }
  
  return(data.frame(
    Year = as.integer(names(year_counts)[valid]),
    Count = as.integer(year_counts[valid]),
    stringsAsFactors = FALSE
  ))
}