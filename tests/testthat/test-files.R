# Data-file lists from repository APIs (Zenodo, figshare, Dataverse, Dryad).

test_that("repository_files reads Zenodo, figshare, Dataverse, and Dryad file lists", {
  local_http(list(
    json_route("https://zenodo.org/api/records/42",
               '{"files": [{"key": "data.csv", "size": 10, "links": {"self": "https://zenodo.org/api/records/42/files/data.csv/content"}}]}'),
    json_route("https://api.figshare.com/v2/articles/777",
               '{"files": [{"name": "t.tsv", "size": 5, "download_url": "https://ndownloader.figshare.com/files/1", "mimetype": "text/tab-separated-values"}]}'),
    json_route("https://dv.example.org/api/datasets/:persistentId/?persistentId=doi%3A10.7910%2FDVN%2FX",
               '{"data": {"latestVersion": {"files": [{"dataFile": {"id": 9, "filename": "a.tab", "contentType": "text/tab-separated-values", "filesize": 7}}]}}}'),
    json_route("https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.x",
               '{"_links": {"stash:version": {"href": "/api/v2/versions/5"}}}'),
    json_route("https://datadryad.org/api/v2/versions/5/files",
               '{"_embedded": {"stash:files": [{"path": "b.nc", "size": 3, "mimeType": "application/x-netcdf", "_links": {"stash:download": {"href": "/api/v2/files/1/download"}}}]}}')
  ))
  z <- repository_files("https://zenodo.org/records/42")
  expect_identical(z[[1]]$url, "https://zenodo.org/api/records/42/files/data.csv/content")
  expect_identical(z[[1]]$type, "text/csv")

  f <- repository_files("https://figshare.com/articles/dataset/title/777/2")
  expect_identical(f[[1]]$url, "https://ndownloader.figshare.com/files/1")

  d <- repository_files("https://dv.example.org/dataset.xhtml?persistentId=doi:10.7910/DVN/X")
  expect_identical(d[[1]]$url, "https://dv.example.org/api/access/datafile/9")
  expect_identical(d[[1]]$size, "7")

  r <- repository_files("https://datadryad.org/dataset/doi:10.5061/dryad.x")
  expect_identical(r[[1]]$url, "https://datadryad.org/api/v2/files/1/download")
  expect_identical(r[[1]]$type, "application/x-netcdf")

  expect_null(repository_files("https://example.org/dataset/1"))
})

test_that("an assessment with no data links gets them from the repository API", {
  local_http(list(
    route("https://zenodo.org/records/42", "<html><head><title>x</title></head></html>"),
    json_route("https://zenodo.org/api/records/42",
               '{"files": [{"key": "data.csv", "size": 10, "links": {"self": "https://zenodo.org/api/records/42/files/data.csv/content"}}]}')
  ))
  a <- assess_fair("https://zenodo.org/records/42", use_datacite = FALSE)
  urls <- vapply(a$metadata$object_content_identifier, function(x) x$url, "")
  expect_identical(urls, "https://zenodo.org/api/records/42/files/data.csv/content")
  df <- as.data.frame(a)
  expect_equal(df$status[df$metric_identifier == "FsF-F3-01M"], "pass")
})
