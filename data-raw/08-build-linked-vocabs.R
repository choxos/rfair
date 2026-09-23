# data-raw/08-build-linked-vocabs.R
#
# Add F-UJI's linked-vocabulary index to R/sysdata.rda: the namespaces of the
# registered semantic vocabularies that FsF-I2-01M checks metadata against
# (LOV, BioPortal, Bioregistry, SeaDataNet, MMI, SWEET, ISO, CESSDA, and
# others). Each entry is a namespace prefix without scheme or "www.", taken from
# linked_vocab.yaml and from the uri_format patterns in linked_vocabs/*.json.
# Also records when and from which F-UJI commit the reference data was built.
#
# Usage (run from the package root, after 01, 04, and 05):
#   FUJI_SRC=~/Documents/GitHub/fuji/fuji_server Rscript data-raw/08-build-linked-vocabs.R

fuji_src <- path.expand(Sys.getenv("FUJI_SRC", unset = "~/Documents/GitHub/fuji/fuji_server"))
data_dir <- file.path(fuji_src, "data")
stopifnot("FUJI_SRC data dir not found" = dir.exists(data_dir))
pkg_root <- normalizePath(".")
sysdata_path <- file.path(pkg_root, "R", "sysdata.rda")
stopifnot("run 01-build-sysdata.R first" = file.exists(sysdata_path))

normalize_ns <- function(x) {
  x <- sub("\\$1.*$", "", x)                 # uri_format: keep the part before the local id
  x <- sub("^[a-z]+://", "", tolower(x))
  sub("^www\\.", "", x)
}

# every "uri_format" value anywhere in a parsed JSON registry file
uri_formats <- function(x) {
  if (!is.list(x)) return(character(0))
  here <- if (is.character(x$uri_format)) x$uri_format else character(0)
  c(here, unlist(lapply(x, uri_formats), use.names = FALSE))
}

lov <- yaml::read_yaml(file.path(data_dir, "linked_vocab.yaml"))
ns <- c(vapply(lov, function(v) v$namespace %||% NA_character_, character(1)),
        unlist(lapply(list.files(file.path(data_dir, "linked_vocabs"), "\\.json$", full.names = TRUE),
                      function(f) uri_formats(jsonlite::read_json(f)))))
ns <- unique(normalize_ns(ns[!is.na(ns)]))
# a namespace needs a host with a dot and something after it
ns <- ns[grepl("^[^/]+\\.[^/]+/.+", ns)]
ns <- sort(ns)

load(sysdata_path)  # -> rfuji_data
rfuji_data$linked_vocab_namespaces <- ns
fuji_commit <- tryCatch(system2("git", c("-C", fuji_src, "rev-parse", "--short", "HEAD"), stdout = TRUE),
                        error = function(e) NA_character_)
rfuji_data$reference_data <- list(
  source = "F-UJI fuji_server/data (https://github.com/pangaea-data-publisher/fuji)",
  core_tables_built = "2026-06-16",
  linked_vocabs_built = format(Sys.Date()),
  linked_vocabs_fuji_commit = fuji_commit)
save(rfuji_data, file = sysdata_path, compress = "xz")
message(sprintf("Added %d linked-vocabulary namespaces to %s (%s)", length(ns), sysdata_path,
                format(structure(file.size(sysdata_path), class = "object_size"), units = "auto")))
