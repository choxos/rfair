# Build the bundled example assessment `fair_example` used by the plot examples
# and the "illustrating-fairness" vignette, so they render offline and
# deterministically (no network on CRAN / CI).
#
# Re-run manually when the engine or the chosen object's metadata changes:
#   Rscript data-raw/06-build-example-assessment.R
#
# Source object: a stable, well-described Zenodo deposit.

devtools::load_all(quiet = TRUE)

id <- "https://doi.org/10.5281/zenodo.8347772"
fair_example <- assess_fair(id, timeout = 60)

# Trim the verbose debug log to keep the installed data small; keep everything
# the print/summary/as.data.frame/plot methods and the vignette rely on.
fair_example$log <- list()
for (i in seq_along(fair_example$results)) {
  fair_example$results[[i]]$debug <- NULL
}

dir.create("data", showWarnings = FALSE)
save(fair_example, file = "data/fair_example.rda", compress = "xz")
message(sprintf("Saved data/fair_example.rda (%.1f KB) - FAIR %s%%",
                file.size("data/fair_example.rda") / 1024,
                formatC(summary(fair_example)$percent[
                  summary(fair_example)$category == "FAIR"],
                  format = "f", digits = 1)))
