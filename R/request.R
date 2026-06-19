# HTTP requests with content negotiation, ported from the RequestHelper in
# fuji_server/helper/request_helper.py. Uses httr2.

#' Perform a content-negotiated HTTP GET.
#'
#' @param url URL to request.
#' @param accept Name of an `ACCEPT_TYPES` profile (e.g. "default",
#'   "datacite_json") or a literal Accept header string.
#' @param timeout Request timeout in seconds.
#' @param max_size Maximum body size to read, in bytes.
#' @param auth Optional list with `token` and `type` ("Basic" or "Bearer").
#' @return A list with `request_url`, `redirect_url` (final URL after
#'   redirects), `status`, `content_type`, `format`, `content` (body string or
#'   NULL), `headers`, and `ok`.
#' @noRd
content_negotiate <- function(url, accept = "default", timeout = 15,
                              max_size = 5e6, auth = NULL) {
  accept_str <- ACCEPT_TYPES[[accept]] %||% accept
  request_url <- sub("#.*$", "", url)

  out <- list(request_url = request_url, redirect_url = NA_character_,
              status = NA_integer_, content_type = NA_character_,
              format = NA_character_, content = NULL, headers = NULL, ok = FALSE)
  if (!is_nonempty_string(request_url)) return(out)

  req <- httr2::request(request_url)
  req <- httr2::req_headers(req, Accept = accept_str)
  req <- httr2::req_user_agent(req, "F-UJI (rfair R package; https://github.com/choxos/rfuji)")
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  if (!is.null(auth) && is_nonempty_string(auth$token)) {
    if (identical(auth$type, "Bearer")) {
      req <- httr2::req_auth_bearer_token(req, auth$token)
    } else {
      req <- httr2::req_headers(req, Authorization = paste("Basic", auth$token))
    }
  }

  resp <- tryCatch(httr2::req_perform(req), error = function(e) {
    out$error <<- conditionMessage(e); NULL
  })
  if (is.null(resp)) return(out)

  out$redirect_url <- tryCatch(resp$url %||% request_url, error = function(e) request_url)
  out$status <- httr2::resp_status(resp)
  out$headers <- tryCatch(as.list(httr2::resp_headers(resp)), error = function(e) NULL)
  ct <- tryCatch(httr2::resp_content_type(resp), error = function(e) NA_character_)
  out$content_type <- ct
  out$format <- guess_format(ct)
  out$content <- tryCatch({
    body <- httr2::resp_body_raw(resp)
    if (length(body) > max_size) body <- body[seq_len(max_size)]
    rawToChar(body)
  }, error = function(e) NULL)
  out$ok <- out$status >= 200 && out$status < 400 && !is.null(out$content)
  out
}

#' Resolve a PID/URL to its final landing-page URL.
#'
#' @param url Identifier URL (e.g. a doi.org URL).
#' @param ... Passed to `content_negotiate()`.
#' @return A list with `landing_url`, `status`, `content`, `content_type`,
#'   `format`, and `ok`.
#' @noRd
resolve_landing_page <- function(url, ...) {
  resp <- content_negotiate(url, accept = "default", ...)
  list(
    landing_url = resp$redirect_url,
    status = resp$status,
    content = resp$content,
    content_type = resp$content_type,
    format = resp$format,
    headers = resp$headers,
    ok = resp$ok
  )
}
