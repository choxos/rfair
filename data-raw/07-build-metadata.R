# data-raw/07-build-metadata.R
#
# Regenerate the citation and archive metadata from DESCRIPTION (and
# inst/CITATION), so it cannot drift from the package metadata:
#   CITATION.cff            via cffr
#   codemeta.json           via codemetar, plus the Zenodo concept DOI
#   .zenodo.json            title and description
#   ro-crate-metadata.json  name and version (set datePublished by hand at release)
#
# Run from the package root before each release (needs network for codemetar's
# GitHub lookups). cffr lists only installed packages as references, so install
# every Suggests package first. cffr and codemetar are build tools, not package
# dependencies:
#   Rscript data-raw/07-build-metadata.R

concept_doi <- "10.5281/zenodo.20775127"
repo <- "https://github.com/choxos/rfair"

d <- as.list(read.dcf("DESCRIPTION")[1, ])
title <- paste0("rfair: ", d$Title)
# Zenodo renders the description as HTML, where "<doi:...>" would parse as a tag.
description <- gsub("<doi:([^>]+)>", "https://doi.org/\\1", gsub("\\s+", " ", d$Description))

write_json <- function(x, path) {
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
}

# CITATION.cff: authors are the "aut"/"cre" people only; the preferred citation
# comes from inst/CITATION; dependencies are listed as references.
cff <- cffr::cff_create("DESCRIPTION")
cffr::cff_write(cff, outfile = "CITATION.cff", verbose = FALSE)

# codemeta.json: contributors and copyright holders come from their DESCRIPTION
# roles; point the identifier at the Zenodo concept DOI.
codemetar::write_codemeta(".", path = "codemeta.json", verbose = FALSE)
cm <- jsonlite::read_json("codemeta.json")
# codemetar writes softwareRequirements as an object keyed "1", "2", ... plus a
# null SystemRequirements entry; CodeMeta readers need an array
for (field in c("softwareRequirements", "softwareSuggestions")) {
  cm[[field]] <- unname(Filter(Negate(is.null), cm[[field]]))
}
cm$identifier <- paste0("https://doi.org/", concept_doi)
cm$description <- description
cm$relatedLink <- unique(c(
  unlist(cm$relatedLink),
  "https://doi.org/10.32614/CRAN.package.rfair",
  paste0("https://archive.softwareheritage.org/browse/origin/?origin_url=", repo)))
write_json(cm, "codemeta.json")

z <- jsonlite::read_json(".zenodo.json")
z$title <- title
z$description <- description
write_json(z, ".zenodo.json")

rc <- jsonlite::read_json("ro-crate-metadata.json")
rc[["@graph"]] <- lapply(rc[["@graph"]], function(node) {
  if (identical(node[["@id"]], "./")) node$name <- title
  if (identical(node[["@id"]], "#rfair")) node$version <- d$Version
  node
})
write_json(rc, "ro-crate-metadata.json")
