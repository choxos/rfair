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

test_that("id_parse classifies a table of real-world identifier shapes", {
  cases <- list(
    # identifier, preferred scheme, persistent, resolver URL
    list("https://doi.org/10.5281/zenodo.8347772", "doi", TRUE, "https://doi.org/10.5281/zenodo.8347772"),
    list("10.1038/sdata.2016.18", "doi", TRUE, "https://doi.org/10.1038/sdata.2016.18"),
    list("DOI: 10.5061/dryad.2rbnzs7k0", "doi", TRUE, "https://doi.org/10.5061/dryad.2rbnzs7k0"),
    list("hdl:10013/epic.45007", "handle", TRUE, "https://hdl.handle.net/10013/epic.45007"),
    list("https://hdl.handle.net/10013/epic.45007", "handle", TRUE, "https://hdl.handle.net/10013/epic.45007"),
    list("20.500.12345/abc", "handle", TRUE, "https://hdl.handle.net/20.500.12345/abc"),
    # plain URLs with numeric path segments are NOT Handles
    list("https://figshare.com/articles/dataset/foo/12345/1", "url", FALSE,
         "https://figshare.com/articles/dataset/foo/12345/1"),
    list("https://example.org/datasets/123/files", "url", FALSE, "https://example.org/datasets/123/files"),
    list("https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/TJCLKP", "doi", TRUE,
         "https://doi.org/10.7910/DVN/TJCLKP"),
    list("https://zenodo.org/records/8347772", "url", FALSE, "https://zenodo.org/records/8347772"),
    list("https://www.ebi.ac.uk/ena/browser/view/PRJEB1787", "url", FALSE,
         "https://www.ebi.ac.uk/ena/browser/view/PRJEB1787"),
    list("https://github.com/choxos/rfair", "url", FALSE, "https://github.com/choxos/rfair"),
    list("https://n2t.net/ark:/13030/tf5p30086k", "ark", TRUE, "http://n2t.net/ark:/13030/tf5p30086k"),
    list("urn:nbn:de:0183-mamo-0000", "urn", TRUE, NA_character_),
    list("geo:GSE12345", "geo", TRUE, "https://identifiers.org/geo:GSE12345"),
    list("https://w3id.org/fair/principles/terms/F1", "w3id", TRUE, "https://w3id.org/fair/principles/terms/F1")
  )
  for (cs in cases) {
    p <- id_parse(cs[[1]])
    expect_identical(p$preferred_schema, cs[[2]], info = cs[[1]])
    expect_identical(p$is_persistent, cs[[3]], info = cs[[1]])
    expect_identical(p$identifier_url, cs[[4]], info = cs[[1]])
  }
})

test_that("id_parse returns empty result for junk input", {
  p <- id_parse("")
  expect_true(is.na(p$preferred_schema))
  expect_false(p$is_persistent)
})
