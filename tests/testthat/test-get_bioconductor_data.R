# extract_version

test_that("extract_version extracts correct version", {
  expect_equal(extract_version("package_1.2.3.tar.gz", "package"), "1.2.3")
  expect_equal(extract_version("some/path/package_4.5.6.tar.gz", "package"), "4.5.6")
  expect_equal(extract_version("https://example.com/package_7.8.9.tar.gz", "package"), "7.8.9")
})

test_that("extract_version returns NULL for invalid paths", {
  expect_null(extract_version("package.tar.gz", "package"))
  expect_null(extract_version("random_1.2.3.tar.gz", "package"))
  expect_null(extract_version("package_1.2.3.txt", "package"))
})

test_that("extract_version handles edge cases", {
  expect_equal(extract_version("package_0.0.1.tar.gz", "package"), "0.0.1")
  expect_equal(extract_version("package_10.0.0.tar.gz", "package"), "10.0.0")
  expect_equal(extract_version("package_1.2.3.4.tar.gz", "package"), "1.2.3.4")
})


# fetch_bioconductor_releases

test_that("fetch_bioconductor_releases returns valid HTML from mock input", {

    mock_fetch <- function(url) {
    list(
      status_code = 200,
      content = charToRaw("<html><head><title>Mock Page</title></head><body><h1>Bioconductor Releases</h1></body></html>")
    )
  }

  # Use stub to replace curl_fetch_memory with the mock function
    mockery::stub(fetch_bioconductor_releases, "curl::curl_fetch_memory", mock_fetch)
  result <- fetch_bioconductor_releases()
  expect_true(inherits(result, "xml_document"))
})

test_that("fetch_bioconductor_releases returns FALSE on 404", {
  # Mock function to simulate a 404 response
  mock_fetch <- function(url) {
    list(
      status_code = 404,
      content = NULL
    )
  }

  # Use stub to replace curl_fetch_memory with the mock function
  mockery::stub(fetch_bioconductor_releases, "curl::curl_fetch_memory", mock_fetch)
  result <- fetch_bioconductor_releases()
  expect_false(result)
})


# parse_bioconductor_releases

test_that("parse_bioconductor_releases correctly extracts release data", {
  # Define mock HTML with a table structure
  mock_html <- "
  <html>
    <body>
      <table>
        <tr>
          <th>Release</th> <th>Date</th> <th>Software Packages</th> <th>R Version</th>
        </tr>
        <tr>
          <td>3.14</td> <td>2021-10-27</td> <td>1890</td> <td>R 4.1</td>
        </tr>
        <tr>
          <td>3.15</td> <td>2022-04-27</td> <td>1945</td> <td>R 4.2</td>
        </tr>
      </table>
    </body>
  </html>
  "

  # Convert to XML document
  html_doc <- read_html(mock_html)

  # Call the function
  result <- parse_bioconductor_releases(html_doc)

  # Expected result
  expected <- list(
    list(release = "3.14", date = "2021-10-27", software_packages = "1890", r_version = "R 4.1"),
    list(release = "3.15", date = "2022-04-27", software_packages = "1945", r_version = "R 4.2")
  )

  # Check the length of parsed results
  expect_length(result, 2)

  # Check if extracted data matches expected output
  expect_equal(result, expected)
})


# fetch_bioconductor_package_info

test_that("fetch_bioconductor_package_info returns main + archive versions", {
  
  # Mock curl::curl_fetch_memory to return raw HTML content
  local_curl_fetch <- function(url) {

    # This mock returns the main package HTML (called early via curl)
    html <- '<html><body><table>
      <tr><td>Version</td><td>3.50.0</td></tr>
      <tr><td>Source Package</td><td>https://bioconductor.org/packages/3.20/bioc/src/contrib/test_limma_3.50.0.tar.gz</td></tr>
    </table></body></html>'
    
    return(list(status_code = 200, content = charToRaw(html)))
  }
  
  local_read_html <- function(x) {
    if (is.list(x) && !is.null(x$content)) {
      message("✅ read_html called with RAW response")
      html_text <- rawToChar(x$content)
      
    } else if (is.character(x) && grepl("^<html>", x)) {
      html_text <- x
      
    } else if (is.character(x) && x == "https://bioconductor.org/packages/3.20/bioc/html/limma.html") {
      html_text <- '<html><body><table>
      <tr><td>Version</td><td>3.50.0</td></tr>
      <tr><td>Source Package</td><td>https://bioconductor.org/packages/3.20/bioc/src/contrib/test_limma_3.50.0.tar.gz</td></tr>
    </table><a href="limma_3.50.0.tar.gz">limma_3.50.0.tar.gz</a></body></html>'
      
    } else if (is.character(x) && x == "https://bioconductor.org/packages/3.20/bioc/src/contrib/Archive/limma/") {
      html_text <- '<html><body>
      <a href="limma_3.48.0.tar.gz">limma_3.48.0.tar.gz</a>
      <a href="limma_3.47.0.tar.gz">limma_3.47.0.tar.gz</a>
    </body></html>'
      
    } else {
      html_text <- "<html></html>"
    }
    xml2::read_html(html_text)
  }
  
  
  my_fn <- fetch_bioconductor_package_info
  mockery::stub(my_fn, "curl::curl_fetch_memory", local_curl_fetch)
  mockery::stub(my_fn, "read_html", local_read_html)
  result <- my_fn("3.20", "limma")
  
  # Assertions
  expect_type(result, "list")
  expect_length(result, 3)
  
  # Check main version
  expect_equal(result[[1]]$version, "3.50.0")
  expect_equal(result[[1]]$source_package, "https://bioconductor.org/packages/3.20/bioc/src/contrib/limma_3.50.0.tar.gz")
  expect_false(result[[1]]$archived)
  
  # Check first archived version
  expect_equal(result[[2]]$version, "3.47.0")
  expect_equal(result[[2]]$source_package, "https://bioconductor.org/packages/3.20/bioc/src/contrib/Archive/limma/limma_3.47.0.tar.gz")
  expect_true(result[[2]]$archived)
  
  # Check second archived version
  expect_equal(result[[3]]$version, "3.48.0")
  expect_equal(result[[3]]$source_package, "https://bioconductor.org/packages/3.20/bioc/src/contrib/Archive/limma/limma_3.48.0.tar.gz")
  expect_true(result[[3]]$archived)
})


test_that("fetch_bioconductor_package_info returns only main version when no archive exists", {
  local_curl_fetch <- function(url) {
    if (grepl("bioc/html/noarchive.html", url)) {
      html <- '<html><body><table>
        <tr><td>Version</td><td>2.10.0</td></tr>
        <tr><td>Source Package</td><td>https://bioconductor.org/packages/3.20/bioc/src/contrib/noarchive_2.10.0.tar.gz</td></tr>
      </table></body></html>'
      return(list(status_code = 200, content = charToRaw(html)))
    }
    if (grepl("src/contrib/Archive/noarchive", url)) {
      return(list(status_code = 404, content = raw(0)))
    }
    return(list(status_code = 404, content = raw(0)))
  }
  
  local_read_html <- function(content) {
    xml2::read_html(rawToChar(content$content))
  }
  
  mockery::stub(fetch_bioconductor_package_info, "curl::curl_fetch_memory", local_curl_fetch)
  mockery::stub(fetch_bioconductor_package_info, "xml2::read_html", local_read_html)
  
  result <- fetch_bioconductor_package_info("3.20", "noarchive")
  
  expect_type(result, "list")
  expect_length(result, 1)
  expect_equal(result[[1]]$source_package, "https://bioconductor.org/packages/3.20/bioc/src/contrib/noarchive_2.10.0.tar.gz")
  expect_equal(result[[1]]$version, "2.10.0")
})



test_that("fetch_bioconductor_package_info returns only archive versions when no main version exists", {
  local_curl_fetch <- function(url) {
    if (grepl("bioc/html/archiveonly.html", url)) {
      return(list(status_code = 404, content = raw(0)))
    }
    if (grepl("src/contrib/Archive/archiveonly", url)) {
      archive_html <- '<html><body>
        <a href="archiveonly_1.0.0.tar.gz">archiveonly_1.0.0.tar.gz</a>
      </body></html>'
      return(list(status_code = 200, content = charToRaw(archive_html)))
    }
    return(list(status_code = 404, content = raw(0)))
  }
  
  local_read_html <- function(content) {
    xml2::read_html(rawToChar(content$content))
  }
  
  mockery::stub(fetch_bioconductor_package_info, "curl::curl_fetch_memory", local_curl_fetch)
  mockery::stub(fetch_bioconductor_package_info, "xml2::read_html", local_read_html)
  
  result <- fetch_bioconductor_package_info("3.20", "archiveonly")
  expect_false(result)
})

test_that("fetch_bioconductor_package_info returns FALSE when package is not found", {
  local_curl_fetch <- function(url) {
    return(list(status_code = 404, content = raw(0)))
  }
  
  local_read_html <- function(content) {
    xml2::read_html(rawToChar(content$content))
  }
  
  mockery::stub(fetch_bioconductor_package_info, "curl::curl_fetch_memory", local_curl_fetch)
  mockery::stub(fetch_bioconductor_package_info, "xml2::read_html", local_read_html)
  
  result <- fetch_bioconductor_package_info("3.20", "doesnotexist")
  expect_false(result)
})


# get_bioconductor_package_url

# Mocked fetch_bioconductor_package_info function
mock_fetch_bioconductor_package_info <- function(bioconductor_version, package_name) {
  # Simulate different Bioconductor versions and package availability
  if (package_name == "DESeq2") {
    return(list(
      version = "1.38.0",
      bioconductor_version = bioconductor_version,
      source_package = paste0("https://bioconductor.org/packages/", bioconductor_version, "/bioc/src/contrib/DESeq2_1.38.0.tar.gz"),
      archived = FALSE
    ))
  } else if (package_name == "edgeR") {
    return(list(
      version = "3.40.2",
      bioconductor_version = bioconductor_version,
      source_package = paste0("https://bioconductor.org/packages/", bioconductor_version, "/bioc/src/contrib/edgeR_3.40.2.tar.gz"),
      archived = FALSE
    ))
  } else {
    return(NULL)  # Simulate non-existing package
  }
}

# Test cases

release_data <- list(
  list(release = "3.17", date = "October 14, 2005"),
  list(release = "3.18", date = "October 4, 2006"),
  list(release = "3.19", date = "October 8, 2007")
)

test_that("get_bioconductor_package_url returns correct URL for DESeq2", {

  mockery::stub(get_bioconductor_package_url, "fetch_bioconductor_package_info", mock_fetch_bioconductor_package_info)
  result <- get_bioconductor_package_url("DESeq2", release_data = release_data)

  expected_url <- "https://bioconductor.org/packages/3.19/bioc/src/contrib/DESeq2_1.38.0.tar.gz"
  expect_equal(result$url, expected_url)
  expect_equal(result$version, "1.38.0")
  expect_false(result$archived)
  expect_type(result$all_versions, "list")
})

test_that("get_bioconductor_package_url returns correct URL for older package version", {
  
  mockery::stub(get_bioconductor_package_url, "fetch_bioconductor_package_info", mock_fetch_bioconductor_package_info)
  result <- get_bioconductor_package_url("edgeR", package_version = "3.40.2", release_data = release_data)

  expected_url <- "https://bioconductor.org/packages/3.19/bioc/src/contrib/edgeR_3.40.2.tar.gz"
  expect_equal(result$url, expected_url)
  expect_equal(result$version, "3.40.2")
  expect_type(result$all_versions, "list")
})

test_that("get_bioconductor_package_url returns NULL for non-existing package", {

  mockery::stub(get_bioconductor_package_url, "fetch_bioconductor_package_info", mock_fetch_bioconductor_package_info)
  result <- get_bioconductor_package_url("NonExistentPackage", release_data = release_data)
  
  expect_null(result$url)
  expect_null(result$version)
})

test_that("get_bioconductor_package_url handles errors gracefully", {
  
  mock_fetch_error <- function(bioconductor_version, package_name) {
    stop("Simulated error")
  }

  mockery::stub(get_bioconductor_package_url, "fetch_bioconductor_package_info", mock_fetch_error)
  result <- get_bioconductor_package_url("DESeq2", release_data = release_data)
  
  expect_null(result$url)
  expect_null(result$version)
})
