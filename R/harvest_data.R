# Data-file harvester: probe content (data) links for type and size, improving
# the data-content and file-format metrics. Reads the response headers of a
# streamed GET, with the 'mime' package guessing the type from the file
# extension when the server gives none.

#' Enrich object_content_identifier entries with MIME type, size, and the HTTP
#' status of the link (probing at most `limit` links, like F-UJI's
#' data_files_limit).
#' @noRd
harvest_data <- function(ctx, timeout = 10, limit = 5) {
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
      # GET, closed once the headers arrive (as F-UJI reads the status of a
      # streamed GET); HEAD hangs on repositories that build files on request
      resp <- rfair_perform(rfair_request(url, timeout = timeout), ctx = ctx,
                            source = "data", headers_only = TRUE)
      if (is_response(resp)) entry$status <- httr2::resp_status(resp)
      # an error page's content-type/length is not the data file's
      info <- if (is_response(resp) && httr2::resp_status(resp) < 400L) {
        list(type = tryCatch(httr2::resp_content_type(resp), error = function(e) NA_character_),
             size = httr2::resp_header(resp, "content-length"))
      }
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
