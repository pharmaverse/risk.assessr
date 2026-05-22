#' Get CRAN Daily Downloads for a Package
#'
#' Retrieves daily CRAN download counts over the past years for a given package,
#' including cumulative downloads.
#'
#' @param pkg Character string, name of the CRAN package.
#' @param years integer, number of past years (default 1) for historical
#'
#' @return A data frame with columns: \code{date}, \code{count}, and \code{cumulative_downloads}.
#'
#' @examples
#' \dontrun{
#'   get_package_download_cran("ggplot2")
#'   # Example output:
#'   #          date  count cumulative_downloads
#'   # 1 2025-04-22  78379           20073615
#'   # 2 2025-04-21  63195           19995236
#'   # 3 2025-04-20  42119           19932041
#'   # 4 2025-04-19  40848           19889922
#'   # 5 2025-04-18  54914           19849074
#'   # 6 2025-04-17  86273           19794160
#'   # 7 2025-04-16  80201           19707887
#' }
#' @export
get_package_download_cran <- function(pkg, years=1) {
  
  if (missing(pkg)) stop("Please provide a package name.")
  
  Sys.setlocale("LC_TIME", "C")
  start_date <- format(Sys.Date() - (years * 365), "%Y-%m-%d")
  end_date <- format(Sys.Date(), "%Y-%m-%d")
  url <- sprintf("https://cranlogs.r-pkg.org/downloads/daily/%s:%s/%s",
                 start_date, end_date, pkg)
  
  read_result <- tryCatch({
    con <- curl::curl(url)
    response <- readLines(con, warn = FALSE)
    close(con)
    jsonlite::fromJSON(paste(response, collapse = ""))
  }, error = function(e) {
    message("Could not fetch CRAN download data for package: ", pkg)
    return(NULL)
  })
  
  # Validate structure
  if (!"downloads" %in% names(read_result) || length(read_result$downloads) == 0) {
    message("No download data found or invalid format for: ", pkg)
    return(NULL)
  }
  
  downloads_df <- read_result$downloads
  
  if (length(downloads_df) == 0) {
    return(NULL)
  }
  
  if (is.list(downloads_df) && !is.data.frame(downloads_df)) {
    downloads_df <- downloads_df[[1]]
    if (length(downloads_df) == 0) 
      return(NULL)
  }
  
  all_data <- downloads_df %>%
    mutate(
      date = as.Date(day),
      count = as.integer(downloads),
      cumulative_downloads = cumsum(count)
    ) %>%
    select(date, count, cumulative_downloads) %>%
    arrange(dplyr::desc(date))
  
  return(all_data)
}

#' Get CRAN Total or Recent Downloads for a Package
#'
#' Retrieves either all-time total downloads or the total from the last `n` full months
#' for a given CRAN package.
#' 
#' Similar data can be obtained via:
#' 
#' https://cranlogs.r-pkg.org/badges/grand-total/ggplot2
#' https://cranlogs.r-pkg.org/badges/last-month/ggplot2
#'
#' @param pkg Character string, the name of the CRAN package.
#' @param months Integer. If NULL, returns all-time total; otherwise, returns total from the last `months` full months (excluding current).
#'
#' @return An integer: total number of downloads.
#'
#' @examples
#' \dontrun{
#'   get_cran_total_downloads("ggplot2")        # all-time total
#'   # 160776616
#'
#'   get_cran_total_downloads("ggplot2", 3)     # last 3 full months
#'   # 4741707
#'
#'   get_cran_total_downloads("ggplot2", 12)    # last 12 full months
#'   # 19878885
#' }
#'
#' @export
get_cran_total_downloads <- function(pkg, months = NULL) {
  
  if (!is.null(months) && (!is.numeric(months) || months < 1)) {
    message("months must be a positive integer")
    return(0)
  }
  
  # build URL
  if (is.null(months)) {
    start <- "2012-10-01"
    end <- format(Sys.Date(), "%Y-%m-%d")
    url <- sprintf("https://cranlogs.r-pkg.org/downloads/total/%s:%s/%s", start, end, pkg)
  } else {
    current_date <- Sys.Date()
    start_of_current_month <- as.Date(format(current_date, "%Y-%m-01"))
    end_date <- start_of_current_month - 1
    start_date <- seq(start_of_current_month, by = paste0("-", months, " months"), length.out = 2)[2]
    url <- sprintf("https://cranlogs.r-pkg.org/downloads/daily/%s:%s/%s", start_date, end_date, pkg)
  }
  
  response <- tryCatch({
    con <- curl::curl(url)
    on.exit(close(con), add = TRUE)
    readLines(con, warn = FALSE)
  }, error = function(e) {
    message("Failed to fetch data: URL not available (", url, ")")
    return(NULL)
  })
  
  if (is.null(response)) {
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(paste(response, collapse = ""))
  
  
  # parse response
  result <- jsonlite::fromJSON(paste(response, collapse = ""))
  
  if (is.null(months)) {
    return(result$downloads)
  }
  
  # daily downloads API: result$downloads is either data.frame or list-column
  downloads <- result$downloads
  
  if (is.data.frame(downloads)) {
    downloads_df <- downloads
  } else if (is.list(downloads) && length(downloads) > 0 && is.data.frame(downloads[[1]])) {
    downloads_df <- downloads[[1]]
  } else {
    return(0)
  }
  
  if (!"downloads" %in% names(downloads_df)) {
    return(0)
  }
  
  total_download <- sum(downloads_df$downloads, na.rm = TRUE)
  return(total_download)
}



# Bioconductor download


#' Get Bioconductor Package Download Statistics
#'
#' Downloads and processes monthly download statistics for a Bioconductor package
#' from the Bioconductor package statistics archive. Returns the full history,
#' the total downloads over the last 6 full months (current month excluded),
#' and the all-time total downloads.
#'
#' @param pkg Character string. The name of a Bioconductor package (e.g. "GenomicRanges").
#'
#' @return A list with three elements:
#' \describe{
#'   \item{all_data}{A data.frame of the full cleaned dataset with dates and cumulative counts.}
#'   \item{total_6_months}{Total downloads in the last 6 complete months.}
#'   \item{total_download}{Total all-time downloads.}
#' }
#'
#' @importFrom curl curl
#' @importFrom utils read.table
#' @importFrom dplyr filter mutate arrange select everything
#'
#' @examples
#' \dontrun{
#'   result <- get_package_download_bioconductor("bioconductorpackage")
#'   print(result$total_6_months)
#'   head(result$all_data)
#'   
#' #$all_data
#' #Date Year Month Nb_of_distinct_IPs Nb_of_downloads Cumulative_downloads
#' #1   2009-01-01 2009   Jan               3341            7053                 7053
#' #2   2009-02-01 2009   Feb               3229            6681                13734
#' #3   2009-03-01 2009   Mar               3753            8021                21755
#'   
#'   #$total_6_months
#'   #[1] 547560
#'   
#'   #$total_download
#'   #[1] 7318550
#' }
#'
#' @export
get_package_download_bioconductor <- function(pkg) {
  
  if (missing(pkg)) 
    stop("Please provide a bioconductor package name.")
  
  # Build the URL
  url <- sprintf(
    "https://bioconductor.org/packages/stats/bioc/%s/%s_stats.tab",
    pkg, pkg
  )
  
  Sys.setlocale("LC_TIME", "C")
  
  empty_list <- list(
    all_data = NULL,
    total_6_months = NULL,
    total_download = NULL
  )
  
  # Try to read the data
  read_result <- tryCatch(
    read.table(curl(url), header = TRUE),
    error = function(e) {
      message("could not fetch download data for package: ", pkg)
      return(empty_list)
    }
  )
  
  if (!is.data.frame(read_result) || nrow(read_result) == 0) {
    message("No download data found for package: ", pkg)
    return(empty_list)
  }
  
  current_date <- Sys.Date()
  start_of_current_month <- as.Date(format(current_date, "%Y-%m-01"))
  
  all_data <- read_result %>%
    filter(Month != "all") %>%
    mutate(
      Month = as.character(Month),
      Year = as.character(Year),
      Date = as.Date(paste(Year, Month, "01"), format = "%Y %b %d")
    ) %>%
    filter(Date < start_of_current_month) %>%
    arrange(Date) %>% 
    mutate(
      Cumulative_downloads = cumsum(Nb_of_downloads),
      Cumulative_IPs = cumsum(Nb_of_distinct_IPs)
    ) %>%
    select(Date, everything())
  
  
  # Get last 6 full months (excluding current)
  start_of_last_month <- as.Date(format(start_of_current_month - 1, "%Y-%m-01"))
  last_6_months_range <- seq(from = start_of_last_month, by = "-1 month", length.out = 6)
  
  last_6_months_data <- all_data %>%
    filter(Date %in% last_6_months_range) %>%
    arrange(Date)
  
  # Totals
  total_6_months <- sum(last_6_months_data$Nb_of_downloads, na.rm = TRUE)
  total_download <- sum(all_data$Nb_of_downloads, na.rm = TRUE)
  
  # Return as a list
  data <- list(
    all_data = all_data,
    total_6_months = total_6_months,
    total_download = total_download
  )
  
  return(data)
}