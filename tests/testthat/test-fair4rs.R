test_that("fair4rs_principles returns the 17 FAIR4RS principles", {
  p <- fair4rs_principles()
  expect_s3_class(p, "data.frame")
  expect_equal(nrow(p), 17)
  expect_setequal(names(p), c("id", "category", "statement", "explanation"))
  expect_setequal(unique(p$category), c("F", "A", "I", "R"))
  expect_true(all(c("F1", "F1.1", "F1.2", "R1.2", "R2", "R3") %in% p$id))
  expect_match(attr(p, "source"), "RDA00068")
  expect_length(attr(p, "foundational"), 4)
})

test_that("fair4rs_principles filters by foundational category", {
  r <- fair4rs_principles("R")
  expect_setequal(r$id, c("R1", "R1.1", "R1.2", "R2", "R3"))
  expect_true(all(r$category == "R"))
})

test_that("principle_definition resolves software metrics to FAIR4RS statements", {
  expect_match(principle_definition("FRSM-17-R1.2"), "provenance")
  expect_match(principle_definition("FRSM-15-R1.1"), "license")
  expect_identical(
    principle_definition("FRSM-08-F4"),
    "Metadata are FAIR, searchable and indexable.")
})

test_that("principle_definition still resolves data metrics to FAIR definitions", {
  d <- principle_definition("FsF-R1.1-01M")
  expect_true(is.character(d) && nzchar(d))
  # the data and software R1.1 definitions come from different sources
  expect_false(identical(d, principle_definition("FRSM-15-R1.1")))
})
