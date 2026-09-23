# CSL JSON metadata collector. doi.org serves Citation Style Language JSON for
# every DOI registration agency (Crossref, DataCite, mEDRA, JaLC, KISTI, ...),
# so one mapper covers DOIs that have no DataCite record. For Crossref DOIs it
# is the only structured registry metadata rfair can negotiate: doi.org answers
# 406 to the DataCite JSON Accept header.

# Registration agencies looked up during this session, keyed by DOI prefix.
.ra_cache <- new.env(parent = emptyenv())

#' DOI registration agency ("DataCite", "Crossref", ...) for the assessed DOI.
#'
#' Checks the bundled prefix table first, then https://doi.org/ra/<prefix>
#' (cached per session). NA when the identifier is not a DOI or the lookup fails.
#' @noRd
doi_registration_agency <- function(ctx, timeout = 15) {
  if (!identical(ctx$pid$preferred_schema, "doi")) return(NA_character_)
  prefix <- sub("/.*$", "", ctx$pid$normalized_id %||% "")
  if (!nzchar(prefix)) return(NA_character_)
  known <- ref_data("doi_prefixes")
  if (prefix %in% names(known)) return(unname(known[[prefix]]))
  if (!is.null(.ra_cache[[prefix]])) return(.ra_cache[[prefix]])
  resp <- content_negotiate(paste0("https://doi.org/ra/", prefix), accept = "json", ctx = ctx,
                            timeout = timeout)
  ra <- NA_character_
  if (isTRUE(resp$ok) && is_nonempty_string(resp$content)) {
    j <- tryCatch(jsonlite::fromJSON(resp$content, simplifyVector = FALSE),
                  error = function(e) NULL)
    ra <- as_chr(jmap(j, "RA"))[1] %||% NA_character_
  }
  .ra_cache[[prefix]] <- ra
  ra
}

#' Format CSL date-parts (list(list(2016, 3, 15))) as "2016-03-15".
#' @noRd
csl_date <- function(d) {
  parts <- as_chr(d[["date-parts"]][[1]])
  if (!length(parts)) return(NULL)
  paste(c(parts[1], sprintf("%02d", as.integer(parts[-1]))), collapse = "-")
}

#' Map a CSL JSON document to reference-schema keys.
#' @noRd
map_csl <- function(j) {
  if (!is.list(j)) return(list())
  out <- list()
  if (is_nonempty_string(j$DOI)) out$object_identifier <- paste0("https://doi.org/", j$DOI)
  out$title <- as_chr(j$title)[1]
  authors <- vapply(j$author %||% list(), function(a) {
    nm <- a$literal %||% a$name %||% trimws(paste(a$given %||% "", a$family %||% ""))
    if (is_nonempty_string(nm)) nm else NA_character_
  }, character(1))
  authors <- authors[!is.na(authors)]
  if (length(authors)) out$creator <- as.list(authors)
  out$publisher <- as_chr(j$publisher)[1]
  out$publication_date <- csl_date(j$issued %||% j$published %||% list())
  out$object_type <- as_chr(j$type)[1]
  if (is_nonempty_string(j$abstract)) {
    out$summary <- trimws(gsub("\\s+", " ", gsub("<[^>]+>", " ", j$abstract)))
  }
  kw <- as_chr(j$subject)
  if (length(kw)) out$keywords <- as.list(kw)
  lic <- unique(as_chr(jmap(j$license, "URL")))
  if (length(lic)) out$license <- as.list(lic)
  out$language <- as_chr(j$language)[1]

  # Crossref full-text links: only "text-mining" links point at the content;
  # "similarity-checking" links are for plagiarism screening.
  links <- Filter(function(l) is.list(l) && is_nonempty_string(l$URL) &&
                    !identical(l[["intended-application"]], "similarity-checking"),
                  j$link %||% list())
  if (length(links)) {
    out$object_content_identifier <- unique_list(lapply(links, function(l) compact(list(
      url = l$URL,
      type = if (!identical(l[["content-type"]], "unspecified")) l[["content-type"]]))))
  }

  rel <- list()
  for (type in names(j$relation %||% list())) {
    for (r in j$relation[[type]]) {
      id <- r$id %||% ""
      if (!nzchar(id)) next
      if (identical(r[["id-type"]], "doi")) id <- paste0("https://doi.org/", id)
      rel[[length(rel) + 1L]] <- list(related_resource = id, relation_type = type)
    }
  }
  if (length(rel)) out$related_resources <- rel
  compact(out)
}

#' Harvest CSL JSON via content negotiation (for non-DataCite DOIs).
#' @noRd
collect_csl <- function(ctx, timeout = 15) {
  if (!identical(ctx$pid$preferred_schema, "doi")) return(invisible())
  ra <- ctx$doi_ra %||% NA_character_
  # DataCite DOIs are covered by the richer DataCite JSON collector
  if (identical(ra, "DataCite")) return(invisible())
  resp <- content_negotiate(ctx$pid_url, accept = "csl_json", timeout = timeout, ctx = ctx)
  if (!isTRUE(resp$ok) || !grepl("csl|citeproc", resp$content_type %||% "", ignore.case = TRUE)) {
    return(invisible())
  }
  j <- tryCatch(jsonlite::fromJSON(resp$content, simplifyVector = FALSE), error = function(e) NULL)
  md <- map_csl(j)
  if (!length(md)) return(invisible())
  merge_metadata(ctx, md, url = resp$redirect_url, method = "csl", format = "csl_json",
                 mimetype = resp$content_type, schema = "https://citationstyles.org/")
  ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
    list(source = "csl", method = "content_negotiation", agency = ra)
  ctx_log(ctx, "FsF-F2-01M", "info", "Harvested CSL JSON via content negotiation")
  invisible()
}
