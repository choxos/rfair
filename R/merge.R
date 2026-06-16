# Metadata normalization and merging, ported from
# fuji_server/harvester/metadata_harvester.py::merge_metadata (:148-299).

#' Levenshtein ratio, equivalent to python-Levenshtein `ratio()`.
#'
#' `ratio = (len_a + len_b - dist) / (len_a + len_b)` where `dist` is the
#' Levenshtein distance with substitution cost 2 (the indel/LCS distance), so
#' this equals `2 * LCS / (len_a + len_b)`.
#' @noRd
levenshtein_ratio <- function(a, b) {
  a <- as.character(a); b <- as.character(b)
  la <- nchar(a); lb <- nchar(b)
  if (la == 0L && lb == 0L) return(1)
  d <- stringdist::stringdist(a, b, method = "lcs")
  1 - d / (la + lb)
}

#' thefuzz-style string preprocessing: lowercase, non-alphanumeric -> space, trim.
#' @noRd
full_process <- function(s) {
  s <- tolower(as.character(s))
  s <- gsub("[^[:alnum:]]+", " ", s)
  trimws(gsub("\\s+", " ", s))
}

#' token_sort_ratio (thefuzz/rapidfuzz): sort whitespace tokens, then ratio*100.
#' @noRd
token_sort_ratio <- function(a, b) {
  sort_tokens <- function(s) {
    toks <- strsplit(full_process(s), " ", fixed = TRUE)[[1]]
    toks <- toks[nzchar(toks)]
    paste(sort(toks), collapse = " ")
  }
  round(levenshtein_ratio(sort_tokens(a), sort_tokens(b)) * 100)
}

#' Order-preserving unique for a list (structural equality via digest).
#' @noRd
unique_list <- function(x) {
  out <- list(); keys <- character(0)
  for (e in x) {
    k <- digest::digest(e)
    if (!(k %in% keys)) { keys <- c(keys, k); out[[length(out) + 1L]] <- e }
  }
  out
}

#' Uniquify related-resource records by their `related_resource` value (last wins).
#' @noRd
unique_related <- function(rels) {
  seen <- character(0); out <- list()
  for (v in rels) {
    rr <- if (is.list(v)) v$related_resource else NULL
    if (is.null(rr) || !is_nonempty_string(rr)) next
    if (!(rr %in% seen)) { seen <- c(seen, rr); out[[length(out) + 1L]] <- v }
    else out[[match(rr, seen)]] <- v
  }
  out
}

#' Merge a harvested metadata record into the engine's normalized state.
#'
#' Mutates `ctx$metadata_merged`, `ctx$metadata_unmerged`,
#' `ctx$related_resources`. Mirrors `merge_metadata` in F-UJI.
#'
#' @param ctx Engine state environment.
#' @param metadict Named list of harvested metadata (reference-schema keys).
#' @param url,method,format,mimetype,schema,namespaces Provenance of the record.
#' @noRd
merge_metadata <- function(ctx, metadict, url = NA_character_, method = NA_character_,
                           format = NA_character_, mimetype = NA_character_,
                           schema = "", namespaces = character()) {
  if (!is.list(metadict) || length(metadict) == 0L) return(invisible())

  for (r in names(metadict)) {
    if (!(r %in% REFERENCE_ELEMENTS || r == "datacite_client")) next
    val <- metadict[[r]]
    if (is.null(val)) next

    # enforce lists for selected elements (:173-178)
    if (r %in% LIST_TYPE_ELEMENTS && is.character(val) && length(val) == 1L) {
      val <- if (r == "keywords") trimws(strsplit(val, ",", fixed = TRUE)[[1]]) else list(val)
    }

    # publisher special case (:182-195)
    if (r == "publisher") {
      if (!is.list(val)) val <- as.list(val)
      val <- lapply(val, function(p) {
        if (is.character(p) && length(p) == 1L) {
          ph <- id_parse(p)
          if (!is.na(ph$preferred_schema)) list(url = p) else list(name = p)
        } else p
      })
    }

    existing <- ctx$metadata_merged[[r]]
    if (!is.null(existing)) {
      existing_scalar <- is.character(existing) && length(existing) == 1L
      val_scalar <- is.character(val) && length(val) == 1L
      msimilarity <- 0
      if (existing_scalar && !identical(existing, val)) {
        msimilarity <- token_sort_ratio(existing, paste(as.character(val), collapse = ""))
      }
      if (is.list(existing) || (is.character(existing) && length(existing) > 1L)) {
        merged <- c(as.list(existing), if (is.list(val)) val else as.list(val))
        ctx$metadata_merged[[r]] <- unique_list(merged)
      } else if (existing_scalar && val_scalar) {
        if (nchar(existing) < nchar(val) && msimilarity > 80) ctx$metadata_merged[[r]] <- val
      }
    } else {
      ctx$metadata_merged[[r]] <- val
    }
  }

  # related resources: extend + uniquify by related_resource (:253-265)
  if (!is.null(metadict$related_resources)) {
    rels <- metadict$related_resources
    if (!is.null(rels) && length(rels) > 0L) {
      ctx$related_resources <- unique_related(c(ctx$related_resources, rels))
    }
  }

  # unmerged provenance record (:282-297)
  rec <- list(method = method, url = url, format = format, mime = mimetype,
              schema = schema, metadata = metadict, namespaces = as.list(namespaces))
  ctx$metadata_unmerged[[length(ctx$metadata_unmerged) + 1L]] <- rec
  invisible()
}
