test_that("license_reuse distinguishes open from present-but-restrictive", {
  expect_true(license_reuse("https://creativecommons.org/licenses/by/4.0/")$is_open)
  expect_true(license_reuse("CC0-1.0")$is_open)
  expect_true(license_reuse("MIT")$is_open)

  ncnd <- license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")
  expect_false(ncnd$is_open)
  expect_false(ncnd$permits_commercial)
  expect_false(ncnd$permits_derivatives)

  expect_false(license_reuse("Some Custom Terms of Use")$is_open)
})

test_that("identifier_hygiene flags layered and non-persistent identifiers", {
  rrid <- identifier_hygiene("RRID:MGI:5577054")
  expect_false(rrid$hygiene_ok)
  expect_true(any(grepl("layered", rrid$issues)))

  expect_true(identifier_hygiene("https://doi.org/10.5281/zenodo.8347772")$hygiene_ok)
  expect_false(identifier_hygiene("ftp://example.org/file.csv")$hygiene_ok)
})

test_that("classify_access detects controlled-access / sensitive sources", {
  a <- classify_access(access_level = "closedAccess",
                       urls = "https://www.ncbi.nlm.nih.gov/gap/?term=phs000424")
  expect_identical(a$access, "closed")
  expect_true(a$controlled_access)
  expect_true(a$sensitive)

  p <- classify_access(access_level = "info:eu-repo/semantics/openAccess")
  expect_identical(p$access, "public")
  expect_false(p$controlled_access)
})

test_that("reusabledata_rating looks up curated sources", {
  expect_identical(reusabledata_rating(source = "dbgap")$id, "dbgap")
  expect_true(is.list(reusabledata_rating(source = "clinvar")))
  expect_null(reusabledata_rating(source = "no-such-source-xyz"))
})

test_that("license_reuse maps to the RDP six-category taxonomy", {
  expect_identical(license_reuse("CC-BY-4.0")$rdp_category, "permissive")
  expect_true(license_reuse("MIT")$facilitates_reuse)
  expect_identical(license_reuse("CC-BY-SA-4.0")$rdp_category, "copyleft")
  expect_identical(license_reuse("CC-BY-NC-ND-4.0")$rdp_category, "restrictive")
  expect_false(license_reuse("CC-BY-NC-ND-4.0")$facilitates_reuse)
  expect_identical(license_reuse("some custom terms")$rdp_category, "unknown")
})

test_that("fair_tlc returns Traceable/Licensed/Connected indicators", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  tlc <- fair_tlc(a)
  expect_setequal(unique(tlc$dimension), c("Traceable", "Licensed", "Connected"))
  expect_equal(nrow(tlc), 5)
  expect_type(tlc$met, "logical")
  expect_match(attr(tlc, "source"), "zenodo.203295")
  expect_error(fair_tlc(list()), "fair_assessment")
})

test_that("fair_principles returns the canonical 15 (sub)principles", {
  fp <- fair_principles()
  expect_equal(nrow(fp), 15)
  expect_true(all(c("F1", "A1.1", "R1.1") %in% fp$id))
  expect_match(principle_definition("FsF-R1.1-01M"), "license", ignore.case = TRUE)
})
