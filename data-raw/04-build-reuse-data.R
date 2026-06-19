# data-raw/04-build-reuse-data.R
#
# Bundle two reference datasets that let rfair address known limitations of
# F-UJI (raised in peer review of the COVID-19 FAIR-assessment paper):
#   1. fair_principles  -- the canonical FAIR principle definitions, from the
#      FAIR-nanopubs vocabulary (w3id.org/fair/principles, cited by go-fair.org).
#   2. reusabledata     -- the (Re)usable Data Project curations of data-source
#      license *reusability* (license presence != open for reuse), so rfair can
#      surface real reuse barriers and controlled-access / sensitive sources.
#
# These augment R/sysdata.rda (built by 01-build-sysdata.R), which must exist.
#
# Usage (from package root):
#   Rscript data-raw/04-build-reuse-data.R

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

find_pkg_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "DESCRIPTION"))) return(d)
    parent <- dirname(d); if (identical(parent, d)) stop("no package root"); d <- parent
  }
}
pkg_root <- find_pkg_root()
comments <- file.path(pkg_root, "comments")

## ---- 1. Canonical FAIR principles (FAIR-nanopubs principles.ttl) -----------
ttl_path <- file.path(comments, "FAIR-nanopubs-master", "principles.ttl")
ttl <- paste(readLines(ttl_path, warn = FALSE), collapse = "\n")
# split into TTL statements (terminated by " .") and keep sub-principle blocks
blocks <- strsplit(ttl, "(?<=\\.)\\s*\\n", perl = TRUE)[[1]]
fair_principles <- list()
for (b in blocks) {
  if (!grepl("FAIR-SubPrinciple", b) || !grepl("#definition", b)) next
  id  <- sub(".*?terms/([A-Za-z0-9.]+)>.*", "\\1", sub("\n.*", "", b), perl = TRUE)
  if (!grepl("^[FAIR][0-9](\\.[0-9])?$", id)) next  # keep F1..R1.3, drop class defs
  lab <- regmatches(b, regexpr("#label>\\s+\"([^\"]+)\"@en", b, perl = TRUE))
  def <- regmatches(b, regexpr("#definition>\\s+\"([^\"]+)\"@en", b, perl = TRUE))
  lab <- sub(".*\"([^\"]+)\"@en", "\\1", lab); def <- sub(".*\"([^\"]+)\"@en", "\\1", def)
  if (!nzchar(id) || !nzchar(def)) next
  category <- substr(id, 1, 1)
  fair_principles[[id]] <- list(
    id = id, label = lab %||% id, category = category, definition = def,
    uri = paste0("https://w3id.org/fair/principles/terms/", id)
  )
}
message(sprintf("FAIR principles extracted: %d (%s)",
                length(fair_principles), paste(names(fair_principles), collapse = ", ")))

## ---- 2. (Re)usable Data Project curations (compiled.json) -------------------
compiled <- jsonlite::fromJSON(
  file.path(comments, "reusabledata-master", "data-sources", "compiled.json"),
  simplifyVector = FALSE
)
host_of <- function(u) {
  if (!is.character(u) || !nzchar(u)) return(NA_character_)
  h <- tryCatch(httr2::url_parse(u)$hostname, error = function(e) NA_character_)
  sub("^www\\.", "", h %||% NA_character_)
}
controlled_terms <- "controlled|protected|identifiable|restricted|consent|dua|hipaa|dbgap|ega"
reusabledata <- lapply(compiled, function(s) {
  issues <- lapply(s$`license-issues` %||% list(), function(i)
    list(criteria = i$criteria %||% NA_character_, comment = i$comment %||% NA_character_))
  commentary <- paste(unlist(s$`license-commentary` %||% list()), collapse = " ")
  data_type <- tolower(s$`data-type` %||% "")
  controlled <- isTRUE(grepl(controlled_terms, tolower(paste(s$description %||% "", commentary)),
                             perl = TRUE)) ||
    (s$`license-type` %||% "") %in% c("unknown", "inconsistent")
  list(
    id = s$id, source = s$source, source_link = s$`source-link`,
    host = host_of(s$`source-link`),
    license = s$license %||% NA_character_,
    license_type = s$`license-type` %||% NA_character_,
    license_link = s$`license-link` %||% NA_character_,
    data_type = data_type,
    n_license_issues = length(issues),
    license_issues = issues,
    controlled_access = controlled,
    sensitive = data_type %in% c("human", "patient", "clinical"),
    commentary = commentary
  )
})
names(reusabledata) <- vapply(reusabledata, function(x) x$id %||% "", character(1))
message(sprintf("reusabledata sources: %d (with hosts: %d)",
                length(reusabledata),
                sum(vapply(reusabledata, function(x) !is.na(x$host), logical(1)))))

## ---- merge into sysdata ----------------------------------------------------
sysdata_path <- file.path(pkg_root, "R", "sysdata.rda")
stopifnot("run 01-build-sysdata.R first" = file.exists(sysdata_path))
load(sysdata_path)  # -> rfuji_data
rfuji_data$fair_principles <- fair_principles
rfuji_data$reusabledata <- reusabledata
save(rfuji_data, file = sysdata_path, compress = "xz")
message(sprintf("Updated %s (%s)", sysdata_path,
                format(structure(file.size(sysdata_path), class = "object_size"), units = "auto")))
