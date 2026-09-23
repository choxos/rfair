# Batch FAIR assessment and interoperability with rtransparent, which extracts
# the identifiers of shared data and code from articles
# (open_data_links / open_code_links: doi.org URLs, repository URLs, and
# identifiers.org prefix:accession codes, joined by " ; ").

#' Split a joined identifier string into individual identifiers.
#'
#' rtransparent joins the data/code identifiers it extracts with `" ; "`. This
#' splits such a string (or a vector of them) into a trimmed character vector,
#' dropping empties. rfair's [id_parse()] already understands the forms it emits
#' (doi.org URLs, repository URLs, and identifiers.org `prefix:accession` codes
#' such as `geo:GSE123` or `bioproject:PRJEB123`).
#'
#' @param x A character vector of identifier strings (each possibly joined).
#' @param sep Separator used to join identifiers (default `" ; "`).
#' @return A character vector of individual identifiers.
#' @export
#' @examples
#' split_identifiers("https://doi.org/10.5061/dryad.x ; geo:GSE12345")
split_identifiers <- function(x, sep = " ; ") {
  x <- unlist(strsplit(as.character(x %||% character()), sep, fixed = TRUE),
              use.names = FALSE)
  x <- trimws(x)
  x[nzchar(x) & !is.na(x) & tolower(x) != "na"]
}

#' @noRd
.assessment_row <- function(id, version, a) {
  base <- data.frame(
    identifier = id, metric_version = version, scheme = NA_character_,
    is_persistent = NA, resolved = NA, http_status = NA_integer_,
    resolved_url = NA_character_, fair_percent = NA_real_, F = NA_real_, A = NA_real_, I = NA_real_,
    R = NA_real_, maturity = NA_real_, n_pass = NA_integer_,
    n_metrics = NA_integer_, error = NA_character_, stringsAsFactors = FALSE
  )
  p <- tryCatch(id_parse(id), error = function(e) NULL)
  if (!is.null(p)) {
    base$scheme <- p$preferred_schema %||% NA_character_
    base$is_persistent <- p$is_persistent %||% NA
  }
  if (!inherits(a, "fair_assessment")) {
    if (inherits(a, "condition")) base$error <- conditionMessage(a)
    return(base)
  }
  s <- summary(a)
  getc <- function(k) { v <- s$percent[s$category == k]; if (length(v)) v[1] else NA_real_ }
  fair <- s[s$category == "FAIR", , drop = FALSE]
  df <- as.data.frame(a)
  if (!is.null(a$resolution)) {
    base$resolved <- isTRUE(a$resolution$ok)
    base$http_status <- as.integer(a$resolution$status %||% NA_integer_)
  }
  base$resolved_url <- a$resolved_url %||% NA_character_
  base$fair_percent <- if (nrow(fair)) fair$percent[1] else NA_real_
  base$F <- getc("F"); base$A <- getc("A"); base$I <- getc("I"); base$R <- getc("R")
  base$maturity <- if (nrow(fair)) fair$maturity[1] else NA_real_
  base$n_pass <- sum(df$status == "pass", na.rm = TRUE)
  base$n_metrics <- nrow(df)
  base
}

#' Assess the FAIRness of a batch of identifiers
#'
#' Runs [assess_fair()] over a vector of identifiers and returns one tidy row per
#' identifier (deduplicated). Failures are captured in an `error` column rather
#' than aborting the batch.
#'
#' @param ids Character vector of DOIs, PIDs, URLs, or identifiers.org codes.
#' @param metric_version Metric version (see [rfair_metric_versions()]).
#' @param quiet If `FALSE` (default), print per-identifier progress.
#' @param workers Number of identifiers to assess at once. Values above 1 fork
#'   worker processes with [parallel::mclapply()], which is not available on
#'   Windows (there the batch runs serially with a warning). HTTP requests to one
#'   host stay rate limited per process (see `options(rfair.rate_per_host)`).
#' @param keep If `TRUE`, keep the full [fair_assessment] objects, named by
#'   identifier, in the `"assessments"` attribute of the result.
#' @param previous Optional result of an earlier `assess_fair_batch()` call.
#'   Identifiers it already scored without an error (for the same metric
#'   version) are reused instead of assessed again, so an interrupted batch can
#'   be resumed.
#' @param ... Passed to [assess_fair()].
#' @return A data frame with one row per unique identifier: `identifier`,
#'   `metric_version`, `scheme`, `is_persistent`, `resolved` (did the
#'   identifier resolve; `NA` when `resolve = FALSE`), `http_status`,
#'   `resolved_url`, `fair_percent`, `F`, `A`, `I`, `R`, `maturity`, `n_pass`,
#'   `n_metrics`, `error`.
#' @seealso [assess_data_code()], [assess_fair()]
#' @export
#' @examples
#' \donttest{
#' res <- assess_fair_batch(c("https://doi.org/10.5281/zenodo.8347772", "geo:GSE12345"),
#'                          keep = TRUE)
#' attr(res, "assessments")[[1]]
#' }
assess_fair_batch <- function(ids, metric_version = "0.8", quiet = FALSE, workers = 1L,
                              keep = FALSE, previous = NULL, ...) {
  ids <- unique(trimws(as.character(ids)))
  ids <- ids[nzchar(ids) & !is.na(ids)]
  if (!length(ids)) return(.assessment_row(character(), metric_version, NULL)[0, ])

  cols <- names(.assessment_row("", "", NULL))
  done <- NULL
  if (is.data.frame(previous) && all(cols %in% names(previous))) {
    done <- previous[previous$metric_version == metric_version & is.na(previous$error) &
                       previous$identifier %in% ids, cols, drop = FALSE]
    done <- done[!duplicated(done$identifier), , drop = FALSE]
  }
  todo <- setdiff(ids, done$identifier)

  one <- function(i) {
    if (!quiet) message(sprintf("[%d/%d] assessing %s", i, length(todo), todo[i]))
    tryCatch(assess_fair(todo[i], metric_version = metric_version, ...), error = function(e) e)
  }
  workers <- as.integer(workers)
  if (workers > 1L && .Platform$OS.type == "windows") {
    warning("workers > 1 needs forking, which Windows lacks; assessing serially.", call. = FALSE)
    workers <- 1L
  }
  results <- if (workers > 1L && length(todo) > 1L) {
    parallel::mclapply(seq_along(todo), one, mc.cores = workers)
  } else {
    lapply(seq_along(todo), one)
  }
  names(results) <- todo

  rows <- lapply(todo, function(id) .assessment_row(id, metric_version, results[[id]]))
  out <- do.call(rbind, c(list(done), rows))
  out <- out[match(ids, out$identifier), , drop = FALSE]
  rownames(out) <- NULL
  if (keep) {
    attr(out, "assessments") <- c(attr(previous, "assessments")[done$identifier],
                                  Filter(function(a) inherits(a, "fair_assessment"), results))
  }
  out
}

#' @noRd
.data_code_worklist <- function(x, id_col, data_col, code_col, sep) {
  rows <- list()
  add <- function(source, kind, links) {
    ids <- split_identifiers(links, sep = sep)
    for (id in ids) rows[[length(rows) + 1L]] <<-
      data.frame(source = as.character(source %||% NA), kind = kind,
                 identifier = id, stringsAsFactors = FALSE)
  }
  if (is.data.frame(x)) {
    src <- if (!is.null(id_col) && id_col %in% names(x)) as.character(x[[id_col]]) else as.character(seq_len(nrow(x)))
    for (i in seq_len(nrow(x))) {
      if (data_col %in% names(x)) add(src[i], "data", x[[data_col]][i])
      if (code_col %in% names(x)) add(src[i], "code", x[[code_col]][i])
    }
  } else if (is.list(x) && (!is.null(x[[data_col]]) || !is.null(x[[code_col]]))) {
    add(NA, "data", x[[data_col]]); add(NA, "code", x[[code_col]])
  } else {
    # a plain character vector of (joined) data links
    for (i in seq_along(x)) add(i, "data", x[[i]])
  }
  if (!length(rows)) return(data.frame(source = character(), kind = character(),
                                       identifier = character(), stringsAsFactors = FALSE))
  do.call(rbind, rows)
}

#' Assess the FAIRness of the data and code shared in articles (rtransparent)
#'
#' Bridges \pkg{rtransparent} and rfair: takes the data/code identifiers
#' rtransparent extracts from articles (its `open_data_links` and
#' `open_code_links` columns) and scores each against the FAIR metrics. Data
#' identifiers are scored with the FsF data metrics and code repositories with
#' the FRSM software metrics.
#'
#' @param x One of: a data frame from `rtransparent::rt_data_code_pmc()` /
#'   `rt_all_pmc()` (with `open_data_links` / `open_code_links` columns); a named
#'   list with those elements; or a character vector of `" ; "`-joined data-link
#'   strings.
#' @param id_col Optional name of a column in `x` identifying the source article
#'   (e.g. `"pmid"` or `"doi"`); used to label each result.
#' @param data_metric_version Metric version for data identifiers (default
#'   `"0.8"`).
#' @param code_metric_version Metric version for code repositories (default
#'   `"0.7_software"`).
#' @param data_col,code_col Column/element names holding the joined links
#'   (defaults match rtransparent: `"open_data_links"`, `"open_code_links"`).
#' @param sep Separator rtransparent uses to join identifiers (default `" ; "`).
#' @param quiet If `FALSE` (default), print per-identifier progress.
#' @param workers,keep See [assess_fair_batch()]. With `keep = TRUE` the
#'   `"assessments"` attribute holds the objects for data and code together.
#' @param previous Optional result of an earlier `assess_data_code()` call, to
#'   resume an interrupted run (see [assess_fair_batch()]).
#' @param ... Passed to [assess_fair()].
#' @return A data frame with one row per (article, kind, identifier): `source`
#'   (article id), `kind` (`"data"` or `"code"`), and the columns of
#'   [assess_fair_batch()]. Each unique identifier is assessed once.
#' @seealso [assess_fair_batch()], [split_identifiers()], [assess_fair()]
#' @export
#' @examples
#' \donttest{
#' assess_data_code(list(open_data_links = "https://doi.org/10.5281/zenodo.8347772",
#'                       open_code_links = "https://github.com/pangaea-data-publisher/fuji"))
#' }
assess_data_code <- function(x, id_col = NULL,
                             data_metric_version = "0.8",
                             code_metric_version = "0.7_software",
                             data_col = "open_data_links",
                             code_col = "open_code_links",
                             sep = " ; ", quiet = FALSE, workers = 1L, keep = FALSE,
                             previous = NULL, ...) {
  work <- .data_code_worklist(x, id_col, data_col, code_col, sep)
  cols <- c("source", "kind", names(.assessment_row("", "", NULL)))
  if (!nrow(work)) {
    empty <- as.data.frame(stats::setNames(rep(list(character()), length(cols)), cols))
    return(empty)
  }
  work$version <- ifelse(work$kind == "code", code_metric_version, data_metric_version)

  batches <- lapply(unique(work$version), function(v) {
    assess_fair_batch(unique(work$identifier[work$version == v]), metric_version = v,
                      quiet = quiet, workers = workers, keep = keep, previous = previous, ...)
  })
  scored <- do.call(rbind, batches)
  key <- function(id, v) paste(id, v, sep = "\r")
  r <- scored[match(key(work$identifier, work$version),
                    key(scored$identifier, scored$metric_version)), , drop = FALSE]
  out <- cbind(source = work$source, kind = work$kind, r, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  if (keep) {
    attr(out, "assessments") <- do.call(c, lapply(batches, attr, "assessments"))
  }
  out
}
