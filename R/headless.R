# Optional headless-browser rendering for JavaScript-heavy landing pages.
# Gated behind the optional 'chromote' package; a no-op if unavailable.

#' Render a landing page with a headless browser and return its HTML.
#' @noRd
render_headless <- function(url, timeout = 30) {
  if (!requireNamespace("chromote", quietly = TRUE) || !is_nonempty_string(url)) return(NULL)
  tryCatch({
    b <- chromote::ChromoteSession$new()
    on.exit(b$close(), add = TRUE)
    b$Page$navigate(url, wait_ = TRUE)
    b$Page$loadEventFired(timeout_ = timeout * 1000)
    doc <- b$DOM$getDocument()
    b$DOM$getOuterHTML(nodeId = doc$root$nodeId)$outerHTML
  }, error = function(e) NULL)
}
