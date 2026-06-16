test_that("fair_example dataset is a usable assessment object", {
  data(fair_example, package = "rfuji")
  expect_s3_class(fair_example, "fair_assessment")
  s <- summary(fair_example)
  expect_true(all(c("F", "A", "I", "R", "FAIR") %in% s$category))
  expect_true(is.finite(s$percent[s$category == "FAIR"]))
})

test_that("plot.fair_assessment draws both types without error", {
  data(fair_example, package = "rfuji")
  tmp <- tempfile(fileext = ".png")

  grDevices::png(tmp, width = 700, height = 450)
  res <- plot(fair_example)
  grDevices::dev.off()
  expect_s3_class(res, "fair_assessment")          # returns x invisibly
  expect_gt(file.size(tmp), 0)

  grDevices::png(tmp, width = 700, height = 650)
  expect_silent(plot(fair_example, type = "metric"))
  grDevices::dev.off()
})

test_that("plot validates its type argument", {
  data(fair_example, package = "rfuji")
  expect_error(plot(fair_example, type = "nope"))
})
