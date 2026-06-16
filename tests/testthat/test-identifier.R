test_that("id_parse recognizes DOIs in several forms", {
  for (x in c("https://doi.org/10.5281/zenodo.8347772",
              "http://dx.doi.org/10.5281/zenodo.8347772",
              "10.5281/zenodo.8347772",
              "doi:10.5281/zenodo.8347772")) {
    p <- id_parse(x)
    expect_identical(p$preferred_schema, "doi")
    expect_true(p$is_persistent)
    expect_identical(p$identifier_url, "https://doi.org/10.5281/zenodo.8347772")
    expect_identical(p$normalized_id, "10.5281/zenodo.8347772")
  }
})

test_that("id_parse handles Handles, URLs, UUIDs and identifiers.org", {
  h <- id_parse("https://hdl.handle.net/11858/00-1734-0000-0003-EE73-2")
  expect_identical(h$preferred_schema, "handle")
  expect_true(h$is_persistent)

  u <- id_parse("https://example.org/dataset/42")
  expect_identical(u$preferred_schema, "url")
  expect_false(u$is_persistent)

  uu <- id_parse("550e8400-e29b-41d4-a716-446655440000")
  expect_identical(uu$preferred_schema, "uuid")
  expect_false(uu$is_persistent)

  io <- id_parse("https://identifiers.org/chebi/CHEBI:36927")
  expect_identical(io$preferred_schema, "chebi")
  expect_true(io$is_persistent)
})

test_that("id_parse returns empty result for junk input", {
  p <- id_parse("")
  expect_true(is.na(p$preferred_schema))
  expect_false(p$is_persistent)
})
