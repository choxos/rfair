# data-raw/05-build-standards.R
#
# Build a namespace/schema-URI -> metadata-standard lookup from fuji's
# metadata_standards.yaml (the RDA Metadata Standards Catalog / FAIRsharing
# curations), used by FsF-R1.3-01M (community-endorsed metadata standard).
# Standards are classified "generic" (multidisciplinary, RDA-endorsed: DataCite,
# Dublin Core, schema.org, DCAT) vs "disciplinary".
#
# Merges into R/sysdata.rda. Usage:
#   FUJI_SRC=~/Documents/GitHub/fuji/fuji_server Rscript data-raw/05-build-standards.R

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x
fuji_src <- path.expand(Sys.getenv("FUJI_SRC", unset = "~/Documents/GitHub/fuji/fuji_server"))
find_pkg_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  repeat { if (file.exists(file.path(d, "DESCRIPTION"))) return(d)
    p <- dirname(d); if (identical(p, d)) stop("no pkg root"); d <- p }
}
pkg_root <- find_pkg_root()

ms <- yaml::read_yaml(file.path(fuji_src, "data", "metadata_standards.yaml"))

# Normalize a namespace URI for matching (drop scheme + trailing /#).
norm_ns <- function(u) sub("[/#]+$", "", sub("^https?://", "", tolower(u)))

# Names/URIs treated as generic (multidisciplinary, RDA/FAIRsharing-endorsed).
generic_re <- "datacite|dublin core|^dc$|dcterms|schema\\.?org|^dcat|data catalog"

metadata_standards <- list()
for (key in names(ms)) {
  std <- ms[[key]]
  name <- std$acronym %||% std$title %||% key
  ids <- std$identifier %||% list()
  uris <- unlist(lapply(ids, function(i) if (i$type %in% c("namespace", "schema")) i$value else NULL))
  if (!length(uris)) next
  is_generic <- grepl(generic_re, tolower(paste(name, key, paste(uris, collapse = " "))), perl = TRUE)
  type <- if (is_generic) "generic" else "disciplinary"
  for (u in uris) {
    metadata_standards[[norm_ns(u)]] <- list(
      name = name, type = type, subject = std$subject_areas %||% std$field_of_science,
      uri = u)
  }
}

sysdata_path <- file.path(pkg_root, "R", "sysdata.rda")
load(sysdata_path)
rfuji_data$metadata_standards <- metadata_standards
save(rfuji_data, file = sysdata_path, compress = "xz")
ngen <- sum(vapply(metadata_standards, function(x) x$type == "generic", logical(1)))
message(sprintf("metadata_standards: %d namespace URIs (%d generic, %d disciplinary); sysdata %s",
                length(metadata_standards), ngen, length(metadata_standards) - ngen,
                format(structure(file.size(sysdata_path), class = "object_size"), units = "auto")))
