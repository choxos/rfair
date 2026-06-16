# Reference metadata schema and constant maps, ported from
# fuji_server/helper/metadata_mapper.py (the `Mapper` enum).

# Names of the reference metadata elements that the harvesters merge into the
# normalized record (Mapper.REFERENCE_METADATA_LIST keys, :39-77).
REFERENCE_ELEMENTS <- c(
  "object_identifier", "creator", "title", "publisher", "publication_date",
  "summary", "keywords", "object_content_identifier", "access_level",
  "access_free", "related_resources", "provenance_general", "measured_variable",
  "contributor", "license", "object_type", "datacite_client", "modified_date",
  "created_date", "right_holder", "object_size", "object_format", "language",
  "license_path", "metadata_service", "coverage_spatial", "coverage_temporal"
)

# Core metadata required by FsF-F2-01M (Mapper.REQUIRED_CORE_METADATA, :80-89).
REQUIRED_CORE_METADATA <- c(
  "creator", "title", "publisher", "publication_date", "summary", "keywords",
  "object_identifier", "object_type"
)

# Elements coerced to lists during merge (metadata_harvester.py:173).
LIST_TYPE_ELEMENTS <- c("keywords", "access_level", "license", "object_type", "publisher")

# CMMI maturity levels (Mapper.MATURITY_LEVELS, :33).
MATURITY_LEVELS <- c("incomplete", "initial", "moderate", "advanced")  # index 0..3

# Access-right code -> canonical condition (Mapper.ACCESS_RIGHT_CODES, :93-107).
ACCESS_RIGHT_CODES <- c(
  c_abf2 = "public", c_f1cf = "embargoed", c_16ec = "restricted",
  c_14cb = "metadataonly", OpenAccess = "public", ClosedAccess = "closed",
  RestrictedAccess = "restricted", NON_PUBLIC = "restricted",
  OP_DATPRO = "embargoed", PUBLIC = "public", RESTRICTED = "restricted",
  SENSITIVE = "restricted", embargoedAccess = "embargoed"
)

# Archive/compression mime types (Mapper.ARCHIVE_COMPRESS_MIMETYPES, :111-119).
ARCHIVE_COMPRESS_MIMETYPES <- c(
  "application/gzip", "application/zstd", "application/octet-stream",
  "application/vnd.ms-cab-compressed", "application/zip", "application/x-gzip",
  "application/x-zip-compressed"
)

#' Map an access-right code or URI to its canonical condition.
#' @noRd
map_access_right <- function(value) {
  if (!is_nonempty_string(value)) return(NA_character_)
  safe <- function(k) if (k %in% names(ACCESS_RIGHT_CODES)) unname(ACCESS_RIGHT_CODES[[k]]) else NA_character_
  v <- safe(value)                       # try direct code
  if (!is.na(v)) return(v)
  safe(sub(".*[/#]", "", value))         # else the trailing path segment of a URI
}
