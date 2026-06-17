test_that("machine-readable API artifacts are packaged", {
  openapi <- system.file("openapi", "rfuji-openapi.yaml", package = "rfuji")
  plumber <- system.file("plumber", "rfuji-api.R", package = "rfuji")

  expect_true(file.exists(openapi))
  expect_true(file.exists(plumber))

  spec <- yaml::read_yaml(openapi)
  expect_equal(spec$openapi, "3.1.0")
  expect_true("/assess" %in% names(spec$paths))
  expect_true("/metric-versions" %in% names(spec$paths))
})
