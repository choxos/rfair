# Canonical FAIR4RS (FAIR Principles for Research Software) definitions.
#
# Principle statements are reproduced from the FAIR Principles for Research
# Software (FAIR4RS Principles) version 1.0 (Chue Hong et al. 2022, RDA
# Recommendation, doi:10.15497/RDA00068, CC BY 4.0). rfair scores software
# against the FRSM operationalization of these principles
# (metric_version = "0.7_software"); this grounds those metrics in the
# authoritative principle text.

.fair4rs <- function() {
  id <- c("F1", "F1.1", "F1.2", "F2", "F3", "F4",
          "A1", "A1.1", "A1.2", "A2",
          "I1", "I2",
          "R1", "R1.1", "R1.2", "R2", "R3")
  category <- c("F", "F", "F", "F", "F", "F",
                "A", "A", "A", "A",
                "I", "I",
                "R", "R", "R", "R", "R")
  statement <- c(
    "Software is assigned a globally unique and persistent identifier.",
    "Components of the software representing levels of granularity are assigned distinct identifiers.",
    "Different versions of the software are assigned distinct identifiers.",
    "Software is described with rich metadata.",
    "Metadata clearly and explicitly include the identifier of the software they describe.",
    "Metadata are FAIR, searchable and indexable.",
    "Software is retrievable by its identifier using a standardized communications protocol.",
    "The protocol is open, free, and universally implementable.",
    "The protocol allows for an authentication and authorization procedure, where necessary.",
    "Metadata are accessible, even when the software is no longer available.",
    "Software reads, writes and exchanges data in a way that meets domain-relevant community standards.",
    "Software includes qualified references to other objects.",
    "Software is described with a plurality of accurate and relevant attributes.",
    "Software is given a clear and accessible license.",
    "Software is associated with detailed provenance.",
    "Software includes qualified references to other software.",
    "Software meets domain-relevant community standards.")
  explanation <- c(
    "The software is given an identifier that is globally unique (refers to only one object, even across systems) and persistent (long-lasting, and resolvable to the identified source).",
    "Distinct components at different granularity levels (e.g. a library and a function within it) are given their own identifiers, with the relationships between them captured in metadata.",
    "Each version of the software, or of a component, is assigned a distinct identifier, with the relationships between versions captured in metadata.",
    "The software is described with rich metadata that is itself FAIR (F4), follows community standards, and uses controlled vocabularies, to support indexing, search, and discovery.",
    "The software's globally unique and persistent identifier is stated explicitly in its associated metadata, making the metadata-to-software association unambiguous.",
    "Metadata about the software are FAIR, readable by humans and machines, and can be published in or harvested by a registry, catalog, repository, or search engine.",
    "Obtaining the software by its identifier uses a standardized communications protocol (such as HTTPS) and does not require specialized or proprietary tools.",
    "The communications protocol (including the identifier resolver) is open, with no restrictions on implementing it, and free, with no fees or licensing costs to implement it.",
    "The protocol supports an authentication and authorization procedure where access conditions (for example licensing, payment, or privilege level) require it.",
    "Metadata describing the software remain accessible even after the software itself is no longer available, since metadata are cheaper to preserve and retain value.",
    "Software reads, writes, and exchanges data using data and metadata types, controlled vocabularies, and formats defined by domain-relevant community standards; where it interacts via APIs these should be documented and open where possible.",
    "Software includes qualified references to the other (non-software) objects it interacts with, such as data, samples, or instruments, specified via identifiers and/or controlled vocabularies.",
    "Software is described with a plurality of accurate and relevant attributes, including but going beyond license (R1.1) and provenance (R1.2), to enable the broadest possible reuse.",
    "Software has a clear, accessible license, ideally machine-readable (for example via an SPDX identifier), that is recognized, minimizes license proliferation, and is compatible with the licenses of its dependencies.",
    "Software is associated with detailed provenance describing why and how it came to be, and who contributed what, when, and where, establishing authenticity and trust.",
    "Software includes qualified references to the other software it is built upon (requirements, imports, libraries) needed to compile and run it, resolvable via the authoritative source.",
    "Software, including its documentation and license, meets domain-relevant community standards and coding practices (for example the package conventions of a programming language, such as CRAN for R).")
  data.frame(id = id, category = category, statement = statement,
             explanation = explanation, stringsAsFactors = FALSE)
}

#' The FAIR Principles for Research Software (FAIR4RS).
#'
#' The canonical FAIR4RS (sub)principles that rfair's software metrics (the FRSM
#' metric set, `metric_version = "0.7_software"`) operationalize. Principle
#' statements are reproduced from the FAIR4RS Principles version 1.0.
#'
#' @param category Optional filter: one or more of `"F"`, `"A"`, `"I"`, `"R"`.
#' @return A data frame with `id`, `category`, `statement` (the principle text),
#'   and `explanation`. The four foundational F/A/I/R statements and the source
#'   citation are attached as the `"foundational"` and `"source"` attributes.
#' @references
#' Chue Hong, N. P., Katz, D. S., Barker, M., Lamprecht, A.-L., Martinez, C.,
#' Psomopoulos, F. E., Harrow, J., Castro, L. J., Gruenpeter, M., Martinez,
#' P. A., Honeyman, T., et al. (2022). FAIR Principles for Research Software
#' (FAIR4RS Principles) (1.0). Research Data Alliance.
#' \doi{10.15497/RDA00068}
#' @seealso [fair_principles()] for the data FAIR principles.
#' @export
#' @examples
#' fair4rs_principles()
#' fair4rs_principles("R")
fair4rs_principles <- function(category = NULL) {
  df <- .fair4rs()
  df <- df[order(match(df$category, c("F", "A", "I", "R")), df$id), ]
  rownames(df) <- NULL
  if (!is.null(category)) df <- df[df$category %in% category, , drop = FALSE]
  rownames(df) <- NULL
  attr(df, "foundational") <- c(
    F = "Software, and its associated metadata, is easy for both humans and machines to find.",
    A = "Software, and its metadata, is retrievable via standardized protocols.",
    I = paste("Software interoperates with other software by exchanging data",
              "and/or metadata, and/or through interaction via application",
              "programming interfaces (APIs), described through standards."),
    R = paste("Software is both usable (can be executed) and reusable (can be",
              "understood, modified, built upon, or incorporated into other",
              "software)."))
  attr(df, "source") <- paste(
    "FAIR Principles for Research Software (FAIR4RS Principles) v1.0;",
    "Chue Hong et al. 2022, Research Data Alliance, doi:10.15497/RDA00068 (CC BY 4.0).")
  df
}
