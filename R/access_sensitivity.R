# Controlled-access and sensitive-data classification.
#
# Addresses a peer-review critique: F-UJI-style tools treat data as simply
# accessible or not, without distinguishing data that is legitimately
# controlled-access or sensitive (e.g. human/clinical data behind a data-use
# agreement). Such data should not be scored as a FAIR failure for being
# restricted. classify_access() surfaces this distinction.

# Hosts known to serve controlled-access / sensitive data.
.CONTROLLED_HOSTS <- c("dbgap", "ncbi.nlm.nih.gov/gap", "ega-archive.org", "ega.crg.eu",
                       "ebi.ac.uk/ega", "jgap", "phenogenet")

#' Look up a (Re)usable Data Project curation for a source.
#'
#' @param urls Character vector of URLs (e.g. landing page, content URLs).
#' @param source Optional source name or id to match.
#' @return The matched curation record (list) or `NULL`.
#' @export
#' @examples
#' reusabledata_rating(source = "dbgap")$license_type
reusabledata_rating <- function(urls = NULL, source = NULL) {
  rd <- ref_data("reusabledata")
  if (is_nonempty_string(source)) {
    key <- tolower(source)
    if (!is.null(rd[[key]])) return(rd[[key]])
    hit <- Filter(function(x) grepl(key, tolower(x$source %||% ""), fixed = TRUE), rd)
    if (length(hit)) return(hit[[1]])
  }
  hosts <- unique(stats::na.omit(vapply(as_chr(urls), function(u) {
    h <- tryCatch(httr2::url_parse(u)$hostname, error = function(e) NA_character_)
    sub("^www\\.", "", h %||% NA_character_)
  }, character(1))))
  for (h in hosts) {
    hit <- Filter(function(x) is_nonempty_string(x$host) &&
                    (identical(x$host, h) || grepl(x$host, h, fixed = TRUE)), rd)
    if (length(hit)) return(hit[[1]])
  }
  NULL
}

#' Classify the access level and sensitivity of a data object.
#'
#' @param access_level Access codes/URIs harvested from metadata (character).
#' @param urls Landing-page and content URLs (for host-based detection).
#' @param source Optional source name/id.
#' @return A list with `access` (public/embargoed/restricted/closed/
#'   metadataonly/unknown), `controlled_access`, `sensitive`, the matched
#'   `reusabledata` record (or NULL), and a human-readable `note`.
#' @export
#' @examples
#' classify_access(access_level = "info:eu-repo/semantics/openAccess")$access
classify_access <- function(access_level = NULL, urls = NULL, source = NULL) {
  cond <- NA_character_
  for (a in as_chr(access_level)) {
    m <- map_access_right(a)
    if (!is.na(m)) { cond <- m; break }
    if (grepl("openAccess", a)) { cond <- "public"; break }
    if (grepl("closedAccess", a)) { cond <- "closed"; break }
    if (grepl("restrictedAccess", a)) { cond <- "restricted"; break }
    if (grepl("embargoedAccess", a)) { cond <- "embargoed"; break }
  }
  access <- cond %||% "unknown"

  rd <- reusabledata_rating(urls = urls, source = source)
  host_controlled <- any(vapply(as_chr(urls), function(u)
    any(vapply(.CONTROLLED_HOSTS, function(h) grepl(h, u, fixed = TRUE), logical(1))),
    logical(1)))

  controlled <- host_controlled || access %in% c("restricted", "closed", "embargoed") ||
    (!is.null(rd) && isTRUE(rd$controlled_access))
  sensitive <- (!is.null(rd) && isTRUE(rd$sensitive)) || host_controlled

  note <- if (controlled && sensitive) {
    "Controlled-access and likely sensitive data: restricted access is expected and should not be scored as a FAIR failure; FAIR for sensitive data emphasizes findable, well-described metadata and documented access procedures."
  } else if (controlled) {
    "Controlled-access data: restricted availability may be legitimate (e.g. data-use agreement); evaluate metadata richness and documented access conditions rather than open download."
  } else if (identical(access, "public")) {
    "Open access."
  } else {
    "Access level could not be determined from metadata."
  }

  list(access = access, controlled_access = controlled, sensitive = sensitive,
       reusabledata = rd, note = note)
}
