make_db <- function(pkgs) {
  df <- do.call(rbind, lapply(pkgs, function(x) {
    data.frame(
      Package    = if (is.null(x$Package)) NA_character_ else x$Package,
      Version    = if (is.null(x$Version)) "1.0.0" else x$Version,
      Depends    = if (is.null(x$Depends)) NA_character_ else x$Depends,
      Imports    = if (is.null(x$Imports)) NA_character_ else x$Imports,
      LinkingTo  = if (is.null(x$LinkingTo)) NA_character_ else x$LinkingTo,
      Suggests   = if (is.null(x$Suggests)) NA_character_ else x$Suggests,
      Enhances   = if (is.null(x$Enhances)) NA_character_ else x$Enhances,
      stringsAsFactors = FALSE
    )
  }))
  rownames(df) <- df$Package
  df
}

test_that("bioconductor_reverse_deps returns reverse Imports", {
  # edgeR and DESeq2 import limma
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",  Imports = "limma"),
    list(Package = "DESeq2", Imports = "limma"),
    list(Package = "other")
  ))

  res <- bioconductor_reverse_deps("limma", which = "Imports", db = db)
  expect_type(res, "list")
  expect_equal(names(res), "Imports")
  expect_setequal(res$Imports, c("edgeR", "DESeq2"))
})

test_that("bioconductor_reverse_deps handles which = 'all'", {
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",  Imports = "limma"),
    list(Package = "DESeq2", Imports = "limma")
  ))

  res <- bioconductor_reverse_deps("limma", which = "all", db = db)
  expect_type(res, "list")
  expect_true(all(c("Depends","Imports","LinkingTo","Suggests","Enhances") %in% names(res)))
  expect_setequal(res$Imports, c("edgeR","DESeq2"))
  # Others should be empty vectors
  expect_length(res$Depends,   0)
  expect_length(res$LinkingTo, 0)
  expect_length(res$Suggests,  0)
  expect_length(res$Enhances,  0)
})

test_that("bioconductor_reverse_deps only.bioc = TRUE filters correctly", {
  # DB has Bioc pkgs edgeR/DESeq2 and a non-Bioc pkg notBioc, all importing limma
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",   Imports = "limma"),
    list(Package = "DESeq2",  Imports = "limma"),
    list(Package = "notBioc", Imports = "limma")
  ))

  # biocdb lists only the Bioconductor packages
  biocdb <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR"),
    list(Package = "DESeq2")
  ))

  res <- bioconductor_reverse_deps("limma", which = "Imports", only.bioc = TRUE, db = db, biocdb = biocdb)
  expect_setequal(res$Imports, c("edgeR","DESeq2"))
  expect_false("notBioc" %in% res$Imports)
})

test_that("bioconductor_reverse_deps returns NULL for invalid which value", {
  db <- make_db(list(list(Package = "limma")))
  res <- bioconductor_reverse_deps("limma", which = "NotARealType", db = db)
  expect_null(res)
})

test_that("bioconductor_reverse_deps returns empty when pkg has no reverse deps", {
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR")  # no imports/depends on limma
  ))
  res <- bioconductor_reverse_deps("limma", which = "Imports", db = db)
  expect_equal(res$Imports, character(0))
})
