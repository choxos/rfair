# License *reusability* assessment.
#
# Addresses a peer-review critique of automated FAIR tools: detecting that a
# license *statement* exists does not mean the data is open for reuse. A
# CC-BY-NC-ND license is present and standard, yet forbids commercial use and
# derivatives, so it fails the Open Definition. license_reuse() classifies the
# actual reuse permissions a license grants.

#' Classify every license found in harvested metadata.
#' @noRd
reuse_from_metadata <- function(license) {
  if (is.null(license)) return(NULL)
  lics <- if (is.character(license) && length(license) == 1L) list(license) else as.list(license)
  # drop access-level statements that repositories mix into the rights field
  access_like <- "info:eu-repo/semantics/|/accessRights|(open|closed|restricted|embargoed)Access"
  cls <- lapply(lics, function(L) {
    if (!is.character(L) || length(L) != 1L) return(NULL)
    if (grepl(access_like, L, perl = TRUE)) return(NULL)
    license_reuse(L)
  })
  cls <- Filter(Negate(is.null), cls)
  if (!length(cls)) return(NULL)
  list(licenses = cls, any_open = any(vapply(cls, function(x) isTRUE(x$is_open), logical(1))))
}

#' Extract non-commercial / no-derivatives / share-alike flags from a CC id.
#' @noRd
cc_flags <- function(id) {
  u <- toupper(id)
  list(nc = grepl("NC", u), nd = grepl("ND", u), sa = grepl("SA", u))
}

#' Resolve a license string to a canonical SPDX-like id.
#' @noRd
resolve_license_id <- function(license) {
  if (!is_nonempty_string(license)) return(NA_character_)
  if (is_url_string(license)) {
    cc <- is_cc_license(license)
    if (isTRUE(cc$iscc)) {
      if (identical(cc$generic, "CC0-1.0")) return("CC0-1.0")
      toks <- regmatches(cc$generic, regexec(
        "creativecommons\\.org/licenses/(by(?:-nc)?(?:-nd)?(?:-sa)?)/([0-9.]+)",
        cc$generic, perl = TRUE))[[1]]
      if (length(toks) >= 3L) return(toupper(paste0("CC-", toks[2], "-", toks[3])))
      return("CC")
    }
    hit <- spdx_lookup_by_url(license)
    if (!is.null(hit)) return(hit$id)
    return(NA_character_)
  }
  # bare string: maybe already an SPDX id, else fuzzy-match by name
  if (grepl("^[A-Za-z0-9.+-]+$", license) && nchar(license) <= 40L) return(license)
  hit <- spdx_lookup_by_name(license)
  if (!is.null(hit)) hit$id else NA_character_
}

#' Assess the reuse permissions granted by a license.
#'
#' Goes beyond detecting that a license exists: classifies whether it actually
#' permits redistribution, commercial use, and derivative works, and whether it
#' meets the Open Definition. Useful for judging real reusability of data.
#'
#' @param license A license name, SPDX id, or URL (e.g. from an assessment).
#' @return A list describing the license's reuse terms, including `is_open`,
#'   `permits_redistribution`, `permits_commercial`, `permits_derivatives`,
#'   `requires_attribution`, `requires_share_alike`, `category`, and `note`.
#' @export
#' @examples
#' license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")$is_open
#' license_reuse("CC-BY-4.0")$is_open
license_reuse <- function(license) {
  out <- list(license = license, spdx_id = NA_character_, family = "unknown",
              is_open = FALSE, permits_redistribution = NA, permits_commercial = NA,
              permits_derivatives = NA, requires_attribution = NA,
              requires_share_alike = NA, category = "custom/unknown",
              rdp_category = "unknown", facilitates_reuse = FALSE,
              note = "License could not be classified; manual review needed for reuse.")
  id <- resolve_license_id(license)
  if (is.na(id)) return(out)
  out$spdx_id <- id
  u <- toupper(id)

  if (grepl("^CC0|^PDDL|PUBLICDOMAIN|^ZERO", u)) {
    out$family <- "public-domain"
    out[c("is_open", "permits_redistribution", "permits_commercial",
          "permits_derivatives")] <- TRUE
    out$requires_attribution <- FALSE; out$requires_share_alike <- FALSE
    out$category <- "open (public domain)"
    out$note <- "Public-domain dedication: open for any reuse."
  } else if (grepl("^CC-BY", u) || grepl("^CC ", u)) {
    f <- cc_flags(u)
    out$family <- "creative-commons"
    out$requires_attribution <- TRUE
    out$permits_redistribution <- TRUE
    out$permits_commercial <- !f$nc
    out$permits_derivatives <- !f$nd
    out$requires_share_alike <- f$sa
    out$is_open <- !f$nc && !f$nd
    out$category <- if (out$is_open) {
      if (f$sa) "open (share-alike)" else "open (attribution)"
    } else if (f$nc && f$nd) "restrictive (non-commercial, no-derivatives)"
    else if (f$nc) "restrictive (non-commercial)" else "restrictive (no-derivatives)"
    out$note <- if (out$is_open) "Meets the Open Definition." else
      "License present but NOT open for reuse (commercial use or derivatives restricted)."
  } else if (grepl("^ODBL", u)) {
    out$family <- "open-data"; out$requires_attribution <- TRUE
    out$requires_share_alike <- TRUE
    out[c("is_open", "permits_redistribution", "permits_commercial",
          "permits_derivatives")] <- TRUE
    out$category <- "open (share-alike)"; out$note <- "Open data license (share-alike)."
  } else if (grepl("^ODC-BY|^CC-BY$", u)) {
    out$family <- "open-data"; out$requires_attribution <- TRUE
    out[c("is_open", "permits_redistribution", "permits_commercial",
          "permits_derivatives")] <- TRUE
    out$category <- "open (attribution)"; out$note <- "Open data license (attribution)."
  } else if (grepl("^(MIT|BSD|APACHE|ISC|ZLIB|UNLICENSE|MPL|WTFPL)", u)) {
    out$family <- "software-permissive"
    out[c("is_open", "permits_redistribution", "permits_commercial",
          "permits_derivatives")] <- TRUE
    out$requires_attribution <- !grepl("UNLICENSE|WTFPL", u)
    out$requires_share_alike <- FALSE
    out$category <- "open (software, permissive)"
    out$note <- "Permissive software license; note this is a software, not a data, license."
  } else if (grepl("^(GPL|LGPL|AGPL|EPL|EUPL)", u)) {
    out$family <- "software-copyleft"
    out[c("is_open", "permits_redistribution", "permits_commercial",
          "permits_derivatives", "requires_share_alike")] <- TRUE
    out$requires_attribution <- TRUE
    out$category <- "open (software, copyleft)"
    out$note <- "Copyleft software license; note this is a software, not a data, license."
  }
  # (Re)usable Data Project six-category taxonomy (Carbon et al. 2019,
  # doi:10.1371/journal.pone.0213090): only "permissive" facilitates reuse
  # without negotiation.
  out$rdp_category <- rdp_category(out)
  out$facilitates_reuse <- identical(out$rdp_category, "permissive")
  out
}

#' Map a classified license to the RDP six-category taxonomy.
#' @noRd
rdp_category <- function(out) {
  if (out$family == "public-domain") return("permissive")
  if (out$family == "software-permissive") return("permissive")
  if (out$family == "software-copyleft") return("copyleft")
  if (out$family %in% c("creative-commons", "open-data")) {
    if (!isTRUE(out$is_open)) return("restrictive")
    return(if (isTRUE(out$requires_share_alike)) "copyleft" else "permissive")
  }
  "unknown"
}
