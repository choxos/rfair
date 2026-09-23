# schema.org microdata and RDFa on landing pages.

microdata_page <- '<html><body>
<div itemscope itemtype="https://schema.org/Dataset">
  <h1 itemprop="name">Ocean temperatures</h1>
  <p itemprop="description">Daily sea surface temperatures.</p>
  <span itemprop="creator" itemscope itemtype="https://schema.org/Person">
    <span itemprop="name">Ada Lovelace</span></span>
  <meta itemprop="keywords" content="ocean">
  <meta itemprop="keywords" content="temperature">
  <link itemprop="license" href="https://creativecommons.org/licenses/by/4.0/">
  <div itemprop="distribution" itemscope itemtype="https://schema.org/DataDownload">
    <a itemprop="contentUrl" href="https://example.org/sst.csv">CSV</a>
    <meta itemprop="encodingFormat" content="text/csv"></div>
</div></body></html>'

rdfa_page <- '<html><body vocab="https://schema.org/">
<div typeof="Dataset">
  <h1 property="name">River discharge</h1>
  <span property="creator" typeof="Person"><span property="name">Grace Hopper</span></span>
  <a property="license" href="https://creativecommons.org/publicdomain/zero/1.0/">CC0</a>
</div></body></html>'

test_that("microdata items are extracted with nesting and multiple values", {
  items <- extract_html_items(xml2::read_html(microdata_page))
  expect_length(items, 1L)
  it <- items[[1]]
  expect_identical(it[["@type"]], "Dataset")
  expect_identical(it$creator$name, "Ada Lovelace")
  expect_identical(unlist(it$keywords), c("ocean", "temperature"))
  md <- map_schemaorg(it)
  expect_identical(md$title, "Ocean temperatures")
  expect_identical(md$license, "https://creativecommons.org/licenses/by/4.0/")
  expect_identical(md$object_content_identifier[[1]]$url, "https://example.org/sst.csv")
})

test_that("RDFa items with a schema.org vocab are extracted", {
  items <- extract_html_items(xml2::read_html(rdfa_page), rdfa = TRUE)
  expect_length(items, 1L)
  md <- map_schemaorg(items[[1]])
  expect_identical(md$title, "River discharge")
  expect_identical(unlist(md$creator), "Grace Hopper")
})

test_that("microdata on a landing page counts as embedded, indexable metadata", {
  local_http(list(route("https://example.org/ds", microdata_page)))
  a <- assess_fair("https://example.org/ds", use_datacite = FALSE)
  df <- as.data.frame(a)
  expect_equal(df$status[df$metric_identifier == "FsF-F4-01M"], "pass")
  expect_equal(df$status[df$metric_identifier == "FsF-I1-01M"], "pass")
  expect_identical(a$metadata$title, "Ocean temperatures")
})
