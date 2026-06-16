test_that("parse_link_header extracts signposting links", {
  hdr <- paste0(
    '<https://ex.org/meta.xml>; rel="describedby"; type="application/xml", ',
    '<https://ex.org/data.csv>; rel="item"; type="text/csv", ',
    '<https://doi.org/10.5072/x>; rel="cite-as", ',
    '<https://ex.org/ignored>; rel="stylesheet"')
  links <- parse_link_header(hdr)
  rels <- vapply(links, function(l) l$rel, character(1))
  expect_setequal(rels, c("describedby", "item", "cite-as"))  # stylesheet dropped
  item <- Filter(function(l) l$rel == "item", links)[[1]]
  expect_identical(item$url, "https://ex.org/data.csv")
  expect_identical(item$type, "text/csv")
})

test_that("map_datacite_xml maps a DataCite resource", {
  xml <- '<resource xmlns="http://datacite.org/schema/kernel-4">
    <identifier identifierType="DOI">10.5072/example</identifier>
    <creators><creator><creatorName>Doe, Jane</creatorName></creator></creators>
    <titles><title>Example Dataset</title></titles>
    <publisher>Example Repo</publisher>
    <publicationYear>2023</publicationYear>
    <resourceType resourceTypeGeneral="Dataset">CSV</resourceType>
    <subjects><subject>testing</subject></subjects>
    <rightsList><rights rightsURI="https://creativecommons.org/licenses/by/4.0/">CC-BY-4.0</rights></rightsList>
    <relatedIdentifiers><relatedIdentifier relationType="IsPartOf">10.5072/parent</relatedIdentifier></relatedIdentifiers>
  </resource>'
  doc <- xml2::read_xml(xml); xml2::xml_ns_strip(doc)
  md <- map_datacite_xml(xml2::xml_find_first(doc, "//resource"))
  expect_identical(md$title, "Example Dataset")
  expect_identical(md$creator, list("Doe, Jane"))
  expect_identical(md$publisher, "Example Repo")
  expect_identical(md$object_type, "Dataset")
  expect_identical(md$publication_date, "2023")
  expect_true("https://creativecommons.org/licenses/by/4.0/" %in% unlist(md$license))
  expect_identical(md$related_resources[[1]]$relation_type, "IsPartOf")
})

test_that("map_dc_xml maps a Dublin Core document", {
  xml <- '<dc xmlns="http://purl.org/dc/elements/1.1/">
    <title>DC Example</title><creator>Smith, John</creator>
    <identifier>https://example.org/1</identifier><subject>kw1</subject>
  </dc>'
  doc <- xml2::read_xml(xml); xml2::xml_ns_strip(doc)
  md <- map_dc_xml(xml2::xml_root(doc))
  expect_identical(md$title, "DC Example")
  expect_identical(md$creator, list("Smith, John"))
  expect_identical(md$object_identifier, "https://example.org/1")
  expect_identical(md$keywords, list("kw1"))
})

test_that("map_mods_xml and map_eml_xml map their schemas", {
  mods <- '<mods xmlns="http://www.loc.gov/mods/v3"><titleInfo><title>M</title></titleInfo>
    <name><namePart>Doe</namePart></name><subject><topic>kw</topic></subject></mods>'
  d <- xml2::read_xml(mods); xml2::xml_ns_strip(d)
  m <- map_mods_xml(xml2::xml_find_first(d, "//mods"))
  expect_identical(m$title, "M"); expect_identical(m$creator, list("Doe"))

  eml <- '<eml xmlns="https://eml.ecoinformatics.org/eml-2.2.0"><dataset>
    <title>E</title><keywordSet><keyword>k1</keyword></keywordSet>
    <abstract><para>desc</para></abstract></dataset></eml>'
  d2 <- xml2::read_xml(eml); xml2::xml_ns_strip(d2)
  e <- map_eml_xml(xml2::xml_find_first(d2, "//eml"))
  expect_identical(e$title, "E"); expect_identical(e$summary, "desc")
})

test_that("collect_xml_doc detects and merges DataCite XML", {
  ctx <- new.env(parent = emptyenv())
  ctx$metadata_merged <- list(); ctx$metadata_unmerged <- list()
  ctx$related_resources <- list(); ctx$metadata_sources <- list(); ctx$test_debug <- FALSE
  xml <- '<resource xmlns="http://datacite.org/schema/kernel-4">
    <titles><title>X</title></titles>
    <creators><creator><creatorName>A</creatorName></creator></creators></resource>'
  expect_true(collect_xml_doc(ctx, xml, url = "u"))
  expect_identical(ctx$metadata_merged$title, "X")
})
