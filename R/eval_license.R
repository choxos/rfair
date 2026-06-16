# FsF-R1.1-01M: data is associated with a machine-readable license.
# Ported from fair_evaluator_license.py (SPDX lookup + Creative Commons regex).

#' Match a license URL against the SPDX registry (lookup_license_by_url).
#' @noRd
spdx_lookup_by_url <- function(u) {
  ul <- if (grepl("spdx.org/licenses", u, fixed = TRUE)) {
    sub("\\.html$", "", sub(".*/", "", u))
  } else NA_character_
  for (item in ref_data("spdx")) {
    if ((!is.na(ul) && identical(item$licenseId, ul)) || any(u == item$seeAlso)) {
      return(list(details_url = sub("\\.json$", ".html", item$detailsUrl),
                  osi = isTRUE(item$isOsiApproved), id = item$licenseId))
    }
  }
  NULL
}

#' Fuzzy-match a license name against SPDX names (lookup_license_by_name, >0.85).
#' @noRd
spdx_lookup_by_name <- function(lvalue) {
  names_lc <- ref_data("spdx_license_names")
  sim <- vapply(names_lc, function(n) levenshtein_ratio(tolower(lvalue), n), numeric(1))
  if (length(sim) && max(sim) > 0.85) {
    item <- ref_data("spdx")[[which.max(sim)]]
    return(list(details_url = sub("\\.json$", ".html", item$detailsUrl),
                osi = isTRUE(item$isOsiApproved), id = item$licenseId))
  }
  NULL
}

#' Detect Creative Commons license URLs (isCreativeCommonsLicense).
#' @noRd
is_cc_license <- function(u) {
  if (grepl("creativecommons.org/publicdomain/", u, fixed = TRUE)) {
    return(list(iscc = TRUE, generic = "CC0-1.0"))
  }
  cc <- "https?://creativecommons\\.org/licenses/(by(-nc)?(-nd)?(-sa)?)/(1\\.0|2\\.0|2\\.5|3\\.0|4\\.0)"
  m <- regmatches(u, regexpr(cc, u, perl = TRUE))
  if (length(m) == 1L) list(iscc = TRUE, generic = m) else list(iscc = FALSE, generic = NULL)
}

#' @noRd
eval_license <- function(ctx, res) {
  mid <- res$metric_identifier
  lics <- ctx$metadata_merged$license
  if (is.null(lics)) return(invisible())
  if (is.character(lics) && length(lics) == 1L) lics <- list(lics)

  license_info <- list()
  for (lic in lics) {
    if (!is.character(lic) || length(lic) != 1L) next
    isurl <- is_url_string(lic)
    valid <- FALSE; spdx_uri <- NULL; osi <- FALSE; id <- NULL
    if (isurl) {
      cc <- is_cc_license(lic)
      if (cc$iscc) { valid <- TRUE; spdx_uri <- lic; id <- cc$generic; osi <- TRUE }
      else {
        hit <- spdx_lookup_by_url(lic)
        if (!is.null(hit)) { spdx_uri <- hit$details_url; osi <- hit$osi; id <- hit$id; valid <- TRUE }
      }
    } else {
      hit <- spdx_lookup_by_name(lic)
      if (!is.null(hit)) { spdx_uri <- hit$details_url; osi <- hit$osi; id <- hit$id; valid <- TRUE }
    }
    license_info[[length(license_info) + 1L]] <- list(
      license = lic, id = id, is_url = isurl, spdx_uri = spdx_uri,
      osi_approved = osi, valid = valid
    )
  }
  res$output <- license_info

  # license metadata element available
  if (crit_is_defined_suffix(res, "-1") && length(license_info) > 0L) {
    crit_pass_suffix(res, "-1", evidence = vapply(license_info, function(x) x$license, character(1)))
  }
  # license is valid and SPDX/CC registered
  if (crit_is_defined_suffix(res, "-2") &&
      any(vapply(license_info, function(x) isTRUE(x$valid), logical(1)))) {
    crit_pass_suffix(res, "-2", evidence = "machine-readable license")
  }
}
