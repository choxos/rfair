# rtransparent harmony: batch assessment of shared data/code identifiers.

test_that("split_identifiers splits, trims, and drops empties", {
  expect_equal(
    split_identifiers("https://doi.org/10.5061/dryad.x ; geo:GSE12345 ; NA ;  "),
    c("https://doi.org/10.5061/dryad.x", "geo:GSE12345")
  )
  expect_equal(split_identifiers(""), character())
  expect_equal(split_identifiers(NA_character_), character())
  expect_equal(split_identifiers(c("a ; b", "c")), c("a", "b", "c"))
})

test_that("assess_data_code ingests an rtransparent-shaped data frame", {
  rt <- data.frame(
    pmid = c("111", "222"),
    open_data_links = c("https://doi.org/10.5281/zenodo.8347772 ; geo:GSE12345", ""),
    open_code_links = c("https://github.com/owner/repo", ""),
    stringsAsFactors = FALSE
  )
  out <- assess_data_code(rt, id_col = "pmid", resolve = FALSE,
                          use_datacite = FALSE, quiet = TRUE)
  expect_s3_class(out, "data.frame")
  expect_true(all(c("source", "kind", "identifier", "scheme", "is_persistent",
                    "fair_percent", "F", "A", "I", "R", "maturity", "error") %in% names(out)))
  expect_equal(nrow(out), 3L)                       # 2 data + 1 code for pmid 111
  expect_setequal(out$source, "111")
  expect_setequal(out$kind, c("data", "code"))
  expect_equal(out$scheme[out$identifier == "geo:GSE12345"], "geo")
  expect_true(out$is_persistent[out$identifier == "geo:GSE12345"])
})

test_that("assess_data_code accepts a named list and dedups identifiers", {
  out <- assess_data_code(
    list(open_data_links = "geo:GSE1 ; geo:GSE1", open_code_links = ""),
    resolve = FALSE, use_datacite = FALSE, quiet = TRUE
  )
  # both work rows resolve to the one unique identifier (assessed once)
  expect_equal(nrow(out), 2L)
  expect_equal(unique(out$identifier), "geo:GSE1")
})

test_that("assess_data_code returns a typed 0-row frame for no links", {
  e <- assess_data_code(data.frame(open_data_links = "", open_code_links = ""))
  expect_s3_class(e, "data.frame")
  expect_equal(nrow(e), 0L)
  expect_true(all(c("source", "kind", "identifier", "fair_percent") %in% names(e)))
})

test_that("assess_fair_batch captures failures in the error column", {
  out <- assess_fair_batch("geo:GSE99", resolve = FALSE, use_datacite = FALSE, quiet = TRUE)
  expect_equal(nrow(out), 1L)
  expect_equal(out$scheme, "geo")
})

test_that("assess_fair_batch keeps assessments and resumes from a previous run", {
  ids <- c("https://doi.org/10.5281/zenodo.8347772", "geo:GSE12345")
  first <- assess_fair_batch(ids[1], quiet = TRUE, resolve = FALSE, keep = TRUE)
  expect_s3_class(attr(first, "assessments")[[ids[1]]], "fair_assessment")

  calls <- 0L
  local_mocked_bindings(assess_fair = function(id, ...) { calls <<- calls + 1L; stop("offline") })
  res <- assess_fair_batch(ids, quiet = TRUE, previous = first, keep = TRUE)
  expect_equal(calls, 1L)                         # only the new identifier was assessed
  expect_identical(res$identifier, ids)           # input order kept
  expect_true(is.na(res$error[1]))                # reused row
  expect_match(res$error[2], "offline")
  expect_named(attr(res, "assessments"), ids[1])
})

test_that("assess_data_code passes resume and keep through to the batches", {
  x <- list(open_data_links = "https://doi.org/10.5281/zenodo.8347772",
            open_code_links = "https://github.com/pangaea-data-publisher/fuji")
  out <- assess_data_code(x, quiet = TRUE, resolve = FALSE, keep = TRUE)
  expect_equal(nrow(out), 2L)
  expect_length(attr(out, "assessments"), 2L)
  local_mocked_bindings(assess_fair = function(id, ...) stop("should not be called"))
  again <- assess_data_code(x, quiet = TRUE, previous = out)
  expect_true(all(is.na(again$error)))
})

test_that("max_time skips the remaining metadata sources and says so", {
  local_http(zenodo_routes())
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", max_time = -1)
  expect_true(length(a$harvest_errors) > 0L)
  expect_match(a$harvest_errors[[1]]$message, "max_time")
  expect_null(a$metadata$title)
})
