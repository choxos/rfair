# data-raw/01-build-sysdata.R
#
# Build R/sysdata.rda from the F-UJI Python source data files. This bakes the
# reference lookup tables (SPDX licenses, file formats, access rights, standard
# protocols, identifiers.org namespaces, default namespaces, DOI prefixes,
# resource/creative-work types) into the package as internal data.
#
# The transformations mirror fuji_server/helper/preprocessor.py exactly so that
# rfair's lookups match upstream F-UJI.
#
# Usage (run from the package root; outputs are checked in):
#   FUJI_SRC=~/Documents/GitHub/fuji/fuji_server Rscript data-raw/01-build-sysdata.R

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

fuji_src <- Sys.getenv("FUJI_SRC", unset = "~/Documents/GitHub/fuji/fuji_server")
fuji_src <- path.expand(fuji_src)
data_dir <- file.path(fuji_src, "data")
stopifnot("FUJI_SRC data dir not found" = dir.exists(data_dir))

# locate package root (dir containing DESCRIPTION), walking up from getwd()
find_pkg_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "DESCRIPTION"))) return(d)
    parent <- dirname(d)
    if (identical(parent, d)) stop("Could not find package root (DESCRIPTION).")
    d <- parent
  }
}
pkg_root <- find_pkg_root()

read_data_yaml <- function(f) yaml::read_yaml(file.path(data_dir, f))

## ---------------------------------------------------------------------------
## SPDX licenses  (preprocessor.retrieve_licenses)
## ---------------------------------------------------------------------------
augment_seealso <- function(seeAlso) {
  out <- as.character(seeAlso %||% character(0))
  if (length(out) == 0) return(out)
  extra <- character(0)
  for (u in out) {
    alt <- if (grepl("http:", u, fixed = TRUE)) sub("http:", "https:", u, fixed = TRUE)
           else sub("https:", "http:", u, fixed = TRUE)
    if (!(alt %in% out)) extra <- c(extra, alt)
    if (endsWith(u, "/legalcode")) extra <- c(extra, sub("/legalcode", "", u, fixed = TRUE))
  }
  c(out, extra)
}
licenses_raw <- read_data_yaml("licenses.yaml")
spdx <- lapply(licenses_raw, function(L) {
  list(
    licenseId     = as.character(L$licenseId %||% NA_character_),
    name          = as.character(L$name %||% NA_character_),  # already lowercase upstream
    detailsUrl    = as.character(L$detailsUrl %||% NA_character_),
    isOsiApproved = isTRUE(L$isOsiApproved),
    seeAlso       = augment_seealso(L$seeAlso)
  )
})
spdx_license_names <- vapply(spdx, function(x) x$name, character(1))

## ---------------------------------------------------------------------------
## File formats  (preprocessor.retrieve_{science,long_term,open}_file_formats)
## -> named list  mime -> domain (or NA); last write wins, matching dict semantics
## ---------------------------------------------------------------------------
file_formats_raw <- read_data_yaml("file_formats.yaml")
derive_formats <- function(ff, reason_str) {
  out <- list()
  for (f in ff) {
    if (reason_str %in% (f$reason %||% character(0))) {
      domain <- if (!is.null(f$domain)) f$domain[[1]] else NA_character_
      for (m in (f$mime %||% character(0))) out[[m]] <- domain
    }
  }
  out
}
science_file_formats   <- derive_formats(file_formats_raw, "scientific format")
long_term_file_formats <- derive_formats(file_formats_raw, "long term format")
open_file_formats      <- derive_formats(file_formats_raw, "open format")

## ---------------------------------------------------------------------------
## Access rights, standard protocols (kept as parsed nested lists)
## ---------------------------------------------------------------------------
access_rights      <- read_data_yaml("access_rights.yaml")
standard_protocols <- read_data_yaml("standard_uri_protocols.yaml")

## ---------------------------------------------------------------------------
## identifiers.org namespaces  (preprocessor.retrieve_identifiers_org_data)
## ---------------------------------------------------------------------------
idorg_raw <- read_data_yaml("identifiers_org_resolver_data.yaml")
identifiers_org <- list()
for (ns in idorg_raw$payload$namespaces) {
  prefix <- ns$prefix %||% NULL
  if (is.null(prefix)) next
  url_pattern <- tryCatch(ns$resources[[1]]$urlPattern, error = function(e) NA_character_)
  identifiers_org[[prefix]] <- list(
    pattern     = as.character(ns$pattern %||% NA_character_),
    url_pattern = as.character(url_pattern %||% NA_character_)
  )
}

## ---------------------------------------------------------------------------
## Default namespaces, DOI prefixes, resource & creative-work types
## ---------------------------------------------------------------------------
# default_namespaces: line.rstrip().rstrip("/#")
dn <- readLines(file.path(data_dir, "default_namespaces.txt"), warn = FALSE)
default_namespaces <- sub("[/#]+$", "", sub("\\s+$", "", dn))
default_namespaces <- default_namespaces[nzchar(default_namespaces)]

# doi_prefixes.tsv: key \t value
dp <- readLines(file.path(data_dir, "doi_prefixes.tsv"), warn = FALSE)
doi_prefixes <- character(0)
for (line in dp) {
  if (grepl("\t", line, fixed = TRUE)) {
    kv <- strsplit(trimws(line), "\t", fixed = TRUE)[[1]]
    if (length(kv) == 2) doi_prefixes[kv[1]] <- kv[2]
  }
}

lc_lines <- function(f) {
  x <- readLines(file.path(data_dir, f), warn = FALSE)
  tolower(trimws(x[nzchar(trimws(x))]))
}
resource_types <- lc_lines("ResourceTypes.txt")
schema_org_creativeworks <- c(lc_lines("creativeworktypes.txt"), lc_lines("bioschemastypes.txt"))

## ---------------------------------------------------------------------------
## Provenance
## ---------------------------------------------------------------------------
fuji_repo <- dirname(fuji_src)
fuji_commit <- tryCatch(
  trimws(system2("git", c("-C", shQuote(fuji_repo), "rev-parse", "HEAD"),
                 stdout = TRUE, stderr = FALSE)),
  error = function(e) NA_character_
)
provenance <- list(
  fuji_source        = fuji_src,
  fuji_commit        = fuji_commit %||% NA_character_,
  built_on           = as.character(Sys.Date()),
  default_metric_version = "0.8"
)

## ---------------------------------------------------------------------------
## Assemble + save
## ---------------------------------------------------------------------------
rfuji_data <- list(
  spdx                     = spdx,
  spdx_license_names       = spdx_license_names,
  science_file_formats     = science_file_formats,
  long_term_file_formats   = long_term_file_formats,
  open_file_formats        = open_file_formats,
  access_rights            = access_rights,
  standard_protocols       = standard_protocols,
  identifiers_org          = identifiers_org,
  default_namespaces       = default_namespaces,
  doi_prefixes             = doi_prefixes,
  resource_types           = resource_types,
  schema_org_creativeworks = schema_org_creativeworks,
  provenance               = provenance
)

out_file <- file.path(pkg_root, "R", "sysdata.rda")
save(rfuji_data, file = out_file, compress = "xz")

message(sprintf("Wrote %s (%s)", out_file,
                format(structure(file.size(out_file), class = "object_size"), units = "auto")))
message(sprintf("  SPDX licenses: %d | science fmts: %d | long-term: %d | open: %d",
                length(spdx), length(science_file_formats),
                length(long_term_file_formats), length(open_file_formats)))
message(sprintf("  identifiers.org namespaces: %d | default ns: %d | DOI prefixes: %d",
                length(identifiers_org), length(default_namespaces), length(doi_prefixes)))
