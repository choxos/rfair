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
    is_persistent = NA, resolved_url = NA_character_,
    fair_percent = NA_real_, F = NA_real_, A = NA_real_, I = NA_real_,
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
#' @param ... Passed to [assess_fair()].
#' @return A data frame with one row per unique identifier: `identifier`,
#'   `metric_version`, `scheme`, `is_persistent`, `resolved_url`,
#'   `fair_percent`, `F`, `A`, `I`, `R`, `maturity`, `n_pass`, `n_metrics`,
#'   `error`.
#' @seealso [assess_data_code()], [assess_fair()]
#' @export
#' @examples
#' \donttest{
#' assess_fair_batch(c("https://doi.org/10.5281/zenodo.8347772", "geo:GSE12345"))
#' }
assess_fair_batch <- function(ids, metric_version = "0.8", quiet = FALSE, ...) {
  ids <- unique(trimws(as.character(ids)))
  ids <- ids[nzchar(ids) & !is.na(ids)]
  if (!length(ids)) return(.assessment_row(character(), metric_version, NULL)[0, ])
  rows <- lapply(seq_along(ids), function(i) {
    if (!quiet) message(sprintf("[%d/%d] assessing %s", i, length(ids), ids[i]))
    a <- tryCatch(assess_fair(ids[i], metric_version = metric_version, ...),
                  error = function(e) e)
    .assessment_row(ids[i], metric_version, a)
  })
  do.call(rbind, rows)
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
                             sep = " ; ", quiet = FALSE, ...) {
  work <- .data_code_worklist(x, id_col, data_col, code_col, sep)
  cols <- c("source", "kind", names(.assessment_row("", "", NULL)))
  if (!nrow(work)) {
    empty <- as.data.frame(stats::setNames(rep(list(character()), length(cols)), cols))
    return(empty)
  }
  work$version <- ifelse(work$kind == "code", code_metric_version, data_metric_version)

  uniq <- unique(work[c("identifier", "version")])
  cache <- vector("list", nrow(uniq))
  for (i in seq_len(nrow(uniq))) {
    if (!quiet) message(sprintf("[%d/%d] assessing %s (v%s)", i, nrow(uniq),
                                uniq$identifier[i], uniq$version[i]))
    a <- tryCatch(assess_fair(uniq$identifier[i], metric_version = uniq$version[i], ...),
                  error = function(e) e)
    cache[[i]] <- .assessment_row(uniq$identifier[i], uniq$version[i], a)
  }
  names(cache) <- paste(uniq$identifier, uniq$version)

  rows <- lapply(seq_len(nrow(work)), function(j) {
    r <- cache[[paste(work$identifier[j], work$version[j])]]
    cbind(source = work$source[j], kind = work$kind[j], r, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
