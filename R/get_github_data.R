#' Fetch GitHub Repository Data
#'
#' This function retrieves metadata about a GitHub repository, including creation date,
#' stars, forks, and the number of recent commits within the last 30 days.
#'
#' @param owner A character string specifying the owner of the repository.
#' @param repo A character string specifying the name of the repository.
#'
#' A GitHub Personal Access Token (PAT) will be needed for some requests or to help with the rate limit.
#' Use Sys.setenv(GITHUB_TOKEN = "personal_access_token") or store your token in a .Renviron file.
#' The token is passed via the `Authorization` header only if `Sys.getenv("GITHUB_TOKEN")` is non-empty.
#'
#' @return A list containing:
#'   - `created_at`: Creation date of the repository.
#'   - `stars`: Number of stars.
#'   - `forks`: Number of forks.
#'   - `date`: Acquisition date (YYYY-MM-DD).
#'   - `recent_commits_count`: Number of commits in the last 30 days.
#'   - `open_issues`: Number of open issues.
#'
#' @details
#' Repository data is fetched using the GitHub API via `curl` and `jsonlite`.
#'
#' @examples
#' \dontrun{
#' result <- get_github_data("tidyverse", "ggplot2")
#' print(result)
#' }
#'
#' @importFrom curl curl_fetch_memory new_handle
#' @importFrom jsonlite fromJSON
#' @export


get_github_data <- function(owner, repo) {
  
  message(glue::glue("Checking GitHub data for {owner}/{repo}..."))
  
  empty_response <- list(
    created_at = NULL,
    stars = NULL,
    forks = NULL,
    date = NULL,
    recent_commits_count = NULL,
    open_issues = NULL
  )
  
  if (is.na(owner) || owner == "") {
    message("Owner is NA or empty. Returning empty response.")
    return(empty_response)
  }
  
  todays_date <- Sys.Date()
  headers <- c(Accept = "application/vnd.github.v3+json")
  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = headers)
  base_url <- "https://api.github.com"
  repo_url <- paste0(base_url, "/repos/", owner, "/", repo)
  
  # Fetch repo details
  repo_resp <- tryCatch({
    resp <- curl::curl_fetch_memory(repo_url, handle = curl::new_handle(httpheader = headers))
    jsonlite::fromJSON(rawToChar(resp$content))
  }, error = function(e) {
    message("Failed to fetch repository details: ", conditionMessage(e))
    return(NULL)
  })
  
  if (is.null(repo_resp)) return(empty_response)
  
  # Parse repo data
  created_at <- repo_resp$created_at
  stars <- repo_resp$stargazers_count
  forks <- repo_resp$forks_count
  open_issues <- repo_resp$open_issues_count
  
  # Fetch commits in last 30 days
  since <- format(todays_date - 30, "%Y-%m-%dT%H:%M:%SZ")
  commits_url <- paste0(base_url, "/repos/", owner, "/", repo, "/commits?since=", since)
  
  commits_resp <- tryCatch({
    resp <- curl::curl_fetch_memory(commits_url, handle = curl::new_handle(httpheader = headers))
    commits_data <- jsonlite::fromJSON(rawToChar(resp$content))
    commits_data
  }, error = function(e) {
    message("Failed to fetch commits: ", conditionMessage(e))
    return(NULL)
  })
  
  if (!is.null(commits_resp)) {
    recent_commits_count <- tryCatch({
      if (is.data.frame(commits_resp)) {
        nrow(commits_resp)
      } else if (!is.null(commits_resp$sha)) {
        length(commits_resp$sha)
      } else {
        0
      }
    }, error = function(e) {
      message("Failed to count recent commits: ", conditionMessage(e))
      0
    })
  } else {
    recent_commits_count <- 0
  }
  
  
  result <- list(
    created_at = format(as.Date(created_at), "%Y-%m-%d"),
    stars = stars,
    forks = forks,
    date = format(todays_date, "%Y-%m-%d"),
    recent_commits_count = recent_commits_count,
    open_issues = open_issues
  )
  
  return(result)
}


#' Retrieve GitHub Commits as Weekly Counts (using curl)
#'
#' This function fetches all commits from a specified GitHub repository
#' using the GitHub API and returns a data frame with weekly commit counts.
#'
#' @param owner Character. The GitHub username or organization that owns the repository.
#' @param repo Character. The name of the GitHub repository.
#' @param years Numeric. Number of years to look back from today's date (default is 1).
#'
#' @return A data frame with four columns:
#' \describe{
#'   \item{week_start}{Start date of the week (class \code{Date}).}
#'   \item{year}{Year of the commits.}
#'   \item{month}{Month of the commits.}
#'   \item{n_commits}{Number of commits during the week.}
#' }
#'
#' @examples
#' \dontrun{
#' # Get commit counts for the past year
#' get_commits_since(owner = "tidyverse", repo = "ggplot2")
#' }
#'
#' @importFrom curl curl_fetch_memory new_handle
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr group_by summarise n arrange mutate select %>%
#' @export
get_commits_since <- function(owner, repo, years = 1) {
  base_url <- "https://api.github.com"
  since <- format(Sys.Date() - years * 365, "%Y-%m-%dT%H:%M:%SZ")
  until <- format(Sys.Date(), "%Y-%m-%dT%H:%M:%SZ")
  
  headers <- c(Accept = "application/vnd.github.v3+json")
  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = headers)
  all_commits <- data.frame()
  page <- 1
  more_pages <- TRUE
  
  while (more_pages) {
    url <- paste0(base_url, "/repos/", owner, "/", repo,
                  "/commits?since=", since,
                  "&until=", until,
                  "&per_page=100&page=", page)
    
    resp <- tryCatch({
      curl::curl_fetch_memory(url, handle = curl::new_handle(httpheader = headers))
    }, error = function(e) {
      message("Failed to fetch page ", page, ": ", conditionMessage(e))
      return(NULL)
    })
    
    if (is.null(resp)) break
    
    commits_data <- tryCatch({
      raw <- rawToChar(resp$content)
      parsed <- jsonlite::fromJSON(raw, flatten = TRUE)
      parsed
    }, error = function(e) {
      message("Error parsing JSON on page ", page, ": ", conditionMessage(e))
      return(NULL)
    })

    if (is.null(commits_data) || (is.list(commits_data) && length(commits_data) == 0)) {
      more_pages <- FALSE
    } else {
      all_commits <- dplyr::bind_rows(all_commits, commits_data)
      page <- page + 1
    }
  }
  

  
  if (nrow(all_commits) == 0) {
    return(data.frame(week_start = as.Date(character()), n_commits = integer()))
  }
  
 
  # Extract commit dates safely
  commit_dates <- as.Date(all_commits$commit.author.date)
  
  # Safeguard
  if (length(commit_dates) == 0 || all(is.na(commit_dates))) {
    return(data.frame(week_start = as.Date(character()), n_commits = integer()))
  }
  
  df <- data.frame(date = commit_dates)
  df$week_start <- as.Date(cut(df$date, breaks = "week", start.on.monday = TRUE))
  
  weekly_df <- df %>%
    group_by(week_start) %>%
    summarise(n_commits = n(), .groups = "drop") %>%
    arrange(desc(week_start)) %>%
    mutate(
      year = as.integer(format(week_start, "%Y")),
      month = as.integer(format(week_start, "%m"))
    ) %>%
    select(week_start, year, month, n_commits)
  
  return(weekly_df)
}

#' Count Commits in the Last Months 
#' 
#' Counts the total number of commits from the last `months` months using a 
#' data frame with weekly commit data (column `week_start`).
#'
#' @param df A data frame with `week_start` (Date) and `n_commits` (int) columns.
#' @param months Integer. Number of months to look back (default is 1).
#' @param today today's date.default is Sys.Date()
#'
#' @return Integer. Total number of commits in the time window.
#'
#' @examples
#' \dontrun{
#' df <- get_commits_since("tidyverse", "ggplot2", years = 1)
#' count_commits_last_months(df, months = 3)
#' }
#' @export
count_commits_last_months <- function(df, months = 1, today = Sys.Date()) {
  if (!all(c("year", "month", "n_commits") %in% names(df))) {
    stop("Data frame must have 'year', 'month', and 'n_commits' columns.")
  }
  
  current_year <- as.integer(format(today, "%Y"))
  current_month <- as.integer(format(today, "%m"))
  
  # Compute the earliest allowed year-month
  start_month <- current_month - months
  start_year <- current_year
  
  while (start_month <= 0) {
    start_month <- start_month + 12
    start_year <- start_year - 1
  }
  
  # Filter rows within range
  within_range <- (df$year > start_year) |
    (df$year == start_year & df$month >= start_month)
  
  within_range <- within_range & (
    (df$year < current_year) |
      (df$year == current_year & df$month <= current_month)
  )
  
  filtered_df <- df[within_range, , drop = FALSE]
  
  if (nrow(filtered_df) == 0) {
    return(0)
  }
  
  sum(filtered_df$n_commits, na.rm = TRUE)
}

#' Extract GitHub repository owner from links
#'
#' Given a vector of GitHub links and a package name, this function finds the link
#' corresponding to the package and extracts the GitHub repository owner.
#'
#' @param links A character vector of GitHub URLs.
#' @param pkg_name A string representing the name of the package.
#'
#' @return A string containing the GitHub repository owner, or NA if not found.
#' @keywords internal
get_repo_owner <- function(links, pkg_name) {
  if (!is.null(links) && all(links != "No GitHub link found")) {
    # Remove trailing slashes
    links <- sub("/+$", "", links)
    
    matching_link <- links[grepl(paste0("/", pkg_name, "$"), links)]
    
    if (length(matching_link) > 0) {
      return(sub("https://github.com/([^/]+)/.*", "\\1", matching_link[1]))
    } else {
      return(NA)
    }
  } else {
    return(NA)
  }
}

#' Calculate Average Time to Close GitHub Issues
#'
#' This function uses the GitHub API to retrieve closed issues from a repository and calculates
#' the average time (in hours) it took to close them, excluding pull requests.
#'
#' @param owner Character. GitHub organization or username.
#' @param repo Character. Repository name.
#' @param max_pages Integer. Maximum number of API result pages to query. Each page can contain up to `per_page` issues. Default is 10.
#' @param per_page Integer. Number of issues to request per page (max 100). Default is 100.
#' @param headers Named character vector of HTTP headers to send with the API request. Default sets GitHub API version.
#'
#' @return Numeric. Average time in hours to close issues, or `NA` if no closed issues were found.
#'
#' @examples
#' \dontrun{
#' average_issue_close_time("tidyverse", "ggplot2")
#' }
#' @export
average_issue_close_time <- function(owner, repo, max_pages = 10, per_page = 100,
                                     headers = c(Accept = "application/vnd.github.v3+json")) {
  
  


  #headers <- c(Accept = "application/vnd.github.v3+json")
  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = headers)
  durations <- numeric(0)
  page <- 1

  repeat {
    if (page > max_pages) break
    
    url <- paste0("https://api.github.com/repos/", owner, "/", repo,
                  "/issues?state=closed&per_page=", per_page, "&page=", page)
    

    handle <- curl::new_handle()
    curl::handle_setheaders(handle, .list = headers)
    
    resp <- tryCatch({
      curl::curl_fetch_memory(url, handle = handle)
    }, error = function(e) {
      message("Failed to fetch page ", page, ": ", conditionMessage(e))
      return(NULL)
    })
    
    
  
    if (is.null(resp)) break
    
    issues <- tryCatch({
      jsonlite::fromJSON(rawToChar(resp$content), flatten = TRUE)
    }, error = function(e) {
      message("Failed to parse page ", page, ": ", conditionMessage(e))
      return(NULL)
    })
   
    if (!is.null(issues$message)) {
      msg <- tolower(issues$message)
      
      if (grepl("abuse detection", msg)) {
        message("GitHub API rate-limited us: ", issues$message)
      } else if (grepl("not found", msg)) {
        message("Repository not found: ", issues$message)
      } else {
        message("GitHub returned a message: ", issues$message)
      }
      
      return(NA)  # <- Clean exit
    }
    
    
    if (!is.data.frame(issues)) {
      message("Issues data is not a data frame. Skipping.")
      return(NA)
    }
    
    
    # Loop through rows safely
    for (i in seq_len(nrow(issues))) {
      issue <- issues[i, ]
      # Safely check for pull_request column
      if (!is.na(issue[["pull_request.url"]]) && nzchar(issue[["pull_request.url"]])) next
      if (is.na(issue$created_at) || is.na(issue$closed_at)) next

      created <- as.POSIXct(issue$created_at, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      closed  <- as.POSIXct(issue$closed_at,  format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      
      if (is.na(created) || is.na(closed)) next

      durations <- c(durations, as.numeric(difftime(closed, created, units = "hours")))
    }
    
    page <- page + 1
  }
 

  
  if (length(durations) == 0) {
    message("No closed issues found.")
    return(NA)
  }

  return(mean(durations, na.rm = TRUE))
}
