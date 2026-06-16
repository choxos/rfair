test_that("launch_rfuji is exported and the bundled app parses", {
  expect_true(is.function(launch_rfuji))
  app <- system.file("shiny-apps", "rfuji", "app.R", package = "rfuji")
  skip_if(!nzchar(app), "bundled app not found in this install")
  expect_silent(parse(app))
})

test_that("launch_rfuji errors clearly without its UI dependencies", {
  # smoke: the function exists and is callable; it will stop() if shiny/bslib/DT
  # are missing, otherwise it would try to run the app (not done in tests).
  skip_if(requireNamespace("shiny", quietly = TRUE) &&
            requireNamespace("bslib", quietly = TRUE) &&
            requireNamespace("DT", quietly = TRUE),
          "UI deps installed; skip the missing-deps path")
  expect_error(launch_rfuji(), "is required to run the rfuji app")
})
