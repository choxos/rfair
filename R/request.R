# HTTP requests with content negotiation, ported from the RequestHelper in
# fuji_server/helper/request_helper.py. Uses httr2.
#
# Every request goes through rfair_request() + rfair_perform(), which apply one
# policy: user agent, timeout, retry on 429/503 (short, capped waits), a
# per-host rate limit, an optional on-disk cache, and an optional guard against
# private and link-local addresses. Options:
#
# * `rfair.max_tries` (default 3): attempts for 429/503 responses.
# * `rfair.rate_per_host` (default 5): requests per second to one host.
# * `rfair.cache_dir` (default unset): directory for an HTTP cache
#   (`httr2::req_cache()`); unset means no cache.
# * `rfair.block_private_hosts` (default FALSE): refuse URLs whose host
#   resolves to a loopback, private, or link-local address, and follow
#   redirects manually so every hop is checked. Turn it on when rfair runs as a
#   service that fetches user-supplied URLs (the bundled Plumber API and Shiny
#   app do).

RFAIR_USER_AGENT <- "F-UJI (rfair R package; https://github.com/choxos/rfair)"

#' Build a request with rfair's shared policy.
#' @noRd
rfair_request <- function(url, timeout = 15, accept = NULL, method = NULL,
                          user_agent = RFAIR_USER_AGENT, retry = TRUE) {
  req <- httr2::request(url)
  if (!is.null(method)) req <- httr2::req_method(req, method)
  if (!is.null(accept)) req <- httr2::req_headers(req, Accept = accept)
  req <- httr2::req_user_agent(req, user_agent)
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  if (retry) {
    req <- httr2::req_retry(
      req, max_tries = getOption("rfair.max_tries", 3L),
      backoff = function(i) min(2^i, 10),
      # honor Retry-After, but never wait more than 10 s per attempt
      after = function(resp) {
        s <- httr2::resp_retry_after(resp)
        if (is.na(s)) NA_real_ else min(s, 10)
      })
  }
  req <- httr2::req_throttle(req, rate = getOption("rfair.rate_per_host", 5))
  cache <- getOption("rfair.cache_dir")
  if (is_nonempty_string(cache)) req <- httr2::req_cache(req, cache)
  req
}

#' Perform a request under rfair's policy.
#'
#' Returns the response, or an `rfair_http_failure` (a list with `message`)
#' when the URL is blocked or the transfer fails. The reason is also recorded
#' in `ctx$harvest_errors` when `ctx` is given.
#' @noRd
rfair_perform <- function(req, ctx = NULL, source = "http") {
  fail <- function(url, msg) {
    add_harvest_error(ctx, source, url, msg)
    structure(list(message = msg), class = "rfair_http_failure")
  }
  guard <- isTRUE(getOption("rfair.block_private_hosts", FALSE))
  url <- req$url
  if (guard) req <- httr2::req_options(req, followlocation = 0L)
  for (hop in 0:10) {
    if (guard) {
      why <- url_block_reason(url)
      if (!is.na(why)) return(fail(url, why))
    }
    resp <- tryCatch(httr2::req_perform(req), error = function(e) e)
    if (inherits(resp, "error")) return(fail(url, conditionMessage(resp)))
    if (!guard) return(resp)
    loc <- httr2::resp_header(resp, "location")
    if (!(httr2::resp_status(resp) %in% c(301L, 302L, 303L, 307L, 308L)) ||
        !is_nonempty_string(loc)) {
      return(resp)
    }
    url <- xml2::url_absolute(loc, url)
    req <- httr2::req_url(req, url)
  }
  fail(url, "too many redirects")
}

#' @noRd
is_response <- function(x) inherits(x, "httr2_response")

#' Why a URL is refused under `rfair.block_private_hosts`, or NA if allowed.
#' @noRd
url_block_reason <- function(url) {
  parts <- tryCatch(httr2::url_parse(url), error = function(e) NULL)
  if (is.null(parts) || !(tolower(parts$scheme %||% "") %in% c("http", "https"))) {
    return("only http and https URLs are allowed")
  }
  host <- parts$hostname %||% ""
  ips <- if (is_ip_literal(host)) host else
    tryCatch(curl::nslookup(host, multiple = TRUE), error = function(e) character(0))
  if (!length(ips)) return(sprintf("host '%s' does not resolve", host))
  bad <- ips[is_private_ip(ips)]
  if (length(bad)) return(sprintf("host '%s' resolves to a non-public address (%s)", host, bad[1]))
  NA_character_
}

#' @noRd
is_ip_literal <- function(host) {
  grepl("^[0-9.]+$", host) || grepl(":", host, fixed = TRUE)
}

#' Loopback, private, link-local, shared, or unspecified IPv4/IPv6 addresses.
#' @noRd
is_private_ip <- function(ip) {
  ip <- tolower(gsub("^\\[|\\]$", "", ip))
  ip <- sub("^::ffff:", "", ip)                     # IPv4-mapped IPv6
  v4 <- grepl("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", ip)
  out <- logical(length(ip))
  if (any(v4)) {
    o <- do.call(rbind, lapply(strsplit(ip[v4], ".", fixed = TRUE), as.integer))
    out[v4] <- o[, 1] %in% c(0L, 10L, 127L) |
      (o[, 1] == 169L & o[, 2] == 254L) |             # link-local, cloud metadata
      (o[, 1] == 172L & o[, 2] >= 16L & o[, 2] <= 31L) |
      (o[, 1] == 192L & o[, 2] == 168L) |
      (o[, 1] == 100L & o[, 2] >= 64L & o[, 2] <= 127L) |  # carrier-grade NAT
      o[, 1] >= 224L                                   # multicast and reserved
  }
  v6 <- !v4
  out[v6] <- ip[v6] %in% c("::", "::1") | grepl("^f[cd]|^fe[89ab]", ip[v6])
  out
}

#' Perform a content-negotiated HTTP GET.
#'
#' @param url URL to request.
#' @param accept Name of an `ACCEPT_TYPES` profile (e.g. "default",
#'   "datacite_json") or a literal Accept header string.
#' @param timeout Request timeout in seconds.
#' @param max_size Maximum body size to keep, in bytes.
#' @param auth Optional list with `token` and `type` ("Basic" or "Bearer").
#' @param ctx Optional engine state, for recording failures.
#' @return A list with `request_url`, `redirect_url` (final URL after
#'   redirects), `status`, `content_type`, `format`, `content` (body string, or
#'   NULL for a binary body), `headers`, and `ok` (2xx or 3xx status).
#' @noRd
content_negotiate <- function(url, accept = "default", timeout = 15,
                              max_size = 5e6, auth = NULL, ctx = NULL) {
  accept_str <- ACCEPT_TYPES[[accept]] %||% accept
  request_url <- sub("#.*$", "", url)

  out <- list(request_url = request_url, redirect_url = NA_character_,
              status = NA_integer_, content_type = NA_character_,
              format = NA_character_, content = NULL, headers = NULL, ok = FALSE)
  if (!is_nonempty_string(request_url)) return(out)

  req <- rfair_request(request_url, timeout = timeout, accept = accept_str)
  if (!is.null(auth) && is_nonempty_string(auth$token)) {
    if (identical(auth$type, "Bearer")) {
      req <- httr2::req_auth_bearer_token(req, auth$token)
    } else {
      req <- httr2::req_headers(req, Authorization = paste("Basic", auth$token))
    }
  }

  resp <- rfair_perform(req, ctx = ctx, source = "http")
  if (!is_response(resp)) {
    out$error <- resp$message
    return(out)
  }
  out$redirect_url <- tryCatch(resp$url %||% request_url, error = function(e) request_url)
  out$status <- httr2::resp_status(resp)
  out$headers <- tryCatch(as.list(httr2::resp_headers(resp)), error = function(e) NULL)
  ct <- tryCatch(httr2::resp_content_type(resp), error = function(e) NA_character_)
  out$content_type <- ct
  out$format <- guess_format(ct)
  out$content <- body_text(resp, max_size)
  out$ok <- out$status >= 200 && out$status < 400
  out
}

#' Is a content type textual (HTML, XML, JSON, RDF, plain text)?
#' @noRd
is_text_type <- function(ct) {
  !is_nonempty_string(ct) ||
    grepl("^text/|json|xml|javascript|turtle|n-triples|n3|html|linkset|yaml",
          tolower(ct))
}

#' Response body as a UTF-8 string, or NULL for binary bodies.
#'
#' Declared charsets are converted to UTF-8; undeclared bodies are read as
#' UTF-8 and fall back to Latin-1 when invalid. NUL bytes are dropped.
#' @noRd
body_text <- function(resp, max_size = 5e6) {
  ct <- httr2::resp_header(resp, "content-type")
  if (!is_text_type(ct)) return(NULL)
  body <- tryCatch(httr2::resp_body_raw(resp), error = function(e) raw())
  if (length(body) > max_size) body <- body[seq_len(max_size)]
  txt <- rawToChar(body[body != as.raw(0)])
  charset <- tolower(regmatches(ct %||% "", regexpr('(?<=charset=)"?[^;" ]+', ct %||% "", perl = TRUE)))
  charset <- gsub('"', "", charset)
  if (length(charset) && !charset %in% c("utf-8", "utf8")) {
    conv <- iconv(txt, from = charset, to = "UTF-8", sub = "?")
    if (!is.na(conv)) return(enc2utf8(conv))
  }
  if (!validUTF8(txt)) txt <- iconv(txt, from = "latin1", to = "UTF-8", sub = "?")
  Encoding(txt) <- "UTF-8"
  txt
}

#' Resolve a PID/URL to its final landing-page URL.
#'
#' @param url Identifier URL (e.g. a doi.org URL).
#' @param ... Passed to `content_negotiate()`.
#' @return A list with `landing_url`, `status`, `content`, `content_type`,
#'   `format`, `headers`, `ok`, and `error` (the transport error, if any).
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
    ok = resp$ok,
    error = resp$error %||% NA_character_
  )
}
