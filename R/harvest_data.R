# Data-file harvester: probe content (data) links for type and size, improving
# the data-content and file-format metrics. Uses HTTP HEAD + the 'mime' package;
# the optional 'wand' package adds libmagic content sniffing.

#' Enrich object_content_identifier entries with MIME type and size.
#' @noRd
harvest_data <- function(ctx, timeout = 10, limit = 3) {
  oci <- ctx$metadata_merged$object_content_identifier
  if (is.null(oci)) return(invisible())
  items <- if (is.list(oci) && is.null(names(oci))) oci else list(oci)

  enriched <- list()
  probed <- 0L
  for (it in items) {
    url <- if (is.list(it)) it$url else it
    entry <- if (is.list(it)) it else list(url = url)
    if (is_nonempty_string(url) && probed < limit) {
      probed <- probed + 1L
      info <- tryCatch({
        req <- httr2::request(url)
        req <- httr2::req_method(req, "HEAD")
        req <- httr2::req_timeout(req, timeout)
        req <- httr2::req_error(req, is_error = function(resp) FALSE)
        req <- httr2::req_user_agent(req, "F-UJI (rfair R package)")
        resp <- httr2::req_perform(req)
        if (httr2::resp_status(resp) >= 400L) {
          NULL  # an error page's content-type/length is not the data file's
        } else {
          list(type = tryCatch(httr2::resp_content_type(resp), error = function(e) NA_character_),
               size = httr2::resp_header(resp, "content-length"))
        }
      }, error = function(e) NULL)
      if (!is.null(info)) {
        if (is.null(entry$type) && is_nonempty_string(info$type)) entry$type <- info$type
        if (is.null(entry$size) && is_nonempty_string(info$size)) entry$size <- info$size
      }
    }
    if (is.null(entry$type) && is_nonempty_string(url)) {
      g <- tryCatch(mime::guess_type(url, empty = NA_character_), error = function(e) NA_character_)
      if (!is.na(g)) entry$type <- g
    }
    enriched[[length(enriched) + 1L]] <- entry
  }
  # deduplicate by canonical URL (collectors may add the same data link twice)
  seen <- character(0); deduped <- list()
  for (e in enriched) {
    u <- if (is.list(e)) e$url else e
    if (is_nonempty_string(u)) {
      if (u %in% seen) next
      seen <- c(seen, u)
    }
    deduped[[length(deduped) + 1L]] <- e
  }
  ctx$metadata_merged$object_content_identifier <- deduped

  # surface a data file format / size to the reusability metrics if missing
  types <- as_chr(lapply(enriched, function(e) if (is.list(e)) e$type else NULL))
  if (is.null(ctx$metadata_merged$object_format) && length(types)) {
    ctx$metadata_merged$object_format <- types[1]
  }
  invisible()
}
