# rfuji engine audit + fixes - 2026-06-17

A four-part audit of the R engine (scoring core, collectors/harvesting,
evaluators, output/S3/plot/app glue) plus `R CMD check --as-cran`. Mechanical
check was clean (0/0/0). The findings below are genuine defects that were fixed;
each is covered by a regression test or verified live. Released in 2.5.0.

## Fixed

### Correctness
- **Access rights under-scored for eu-repo records** (`R/reference_schema.R`).
  `ACCESS_RIGHT_CODES` keys are capitalized (`OpenAccess`) but eu-repo URIs use
  lowercase-initial tokens (`info:eu-repo/semantics/openAccess`), so
  `map_access_right` returned `NA` for open/closed/restricted access and
  `FsF-A1-01M` test -2 failed for nearly all eu-repo objects. Now matched
  case-insensitively.
- **XML metadata leaked `NA` fields, inflating core-metadata scores**
  (`R/mapping.R::compact`). XPath extractors return scalar `NA` for absent
  fields; `compact` dropped only `NULL`/length-0, so `title=NA` etc. survived
  into the merge and were counted as present by `eval_core_metadata`. `compact`
  now also drops scalar `NA`.
- **Recommended file formats with mixed-case MIME types never matched**
  (`R/eval_reusable.R`). `candidates` were lowercased but the reference keys were
  not, so formats like `application/CCP4-mtz` could never pass `FsF-R1.3-02D`.
  Reference keys are now lowercased too.

### Crashes
- **`plot(type = "category")` errored on metric sets missing a FAIR category**
  (`R/plot.R`). `summary()` returns NA rows for absent categories (e.g. `0.5ss`
  has no A, `0.6a2a` only F); `.draw_bar` hit `if (NA > 0)`. NA percents are now
  coerced to 0 and `.draw_bar` guards NA.
- **Shiny app crashed (subscript out of bounds) for absent categories and NA
  maturity** (`inst/shiny-apps/rfuji/app.R`). `MATURITY_COLORS[[NA]]` in the
  category cards and the maturity value box. Category cards now render only for
  principles the metric set defines, and maturity colors default safely.
- **Plots/`as.data.frame` errored on an empty-results assessment**
  (`R/fair_assessment.R`). `as.data.frame.fair_assessment` returned `NULL` for
  zero results, so the plot subset failed before its 0-metric guard. It now
  returns a typed 0-row data frame.

### Robustness
- **A malformed response from one source aborted the whole harvest**
  (`R/collect_datacite.R::harvest_all_metadata`). Each collector now runs in its
  own `tryCatch`, so a bad source is logged and skipped, not fatal.
- **Data-file HEAD probe recorded error-page content types** (`R/harvest_data.R`).
  A 4xx/5xx data link's `text/html` error page was recorded as the data file's
  type/format. HEAD responses with status >= 400 are now ignored.
- **Signposting dropped space-separated `rel` values and read link params from
  the URL query** (`R/signposting.R`). `rel="describedby alternate"` is now
  matched per-token, and link params are read only from the param segments
  (not the `<URL>`'s query string).
- **(X)HTML landing pages were mined as Dublin Core XML** (`R/collect_xml.R`).
  The generic-DC branch fired on any document with a `<title>`; it now excludes
  documents whose root element is `html`.

### Latent / API honesty
- **`test_scoring_mechanism`** (`R/criterium_engine.R`). 2.5.0 changed
  `crit_pass` to award `max` for `alternative` metrics. **Reverted in 2.6.0**:
  F-UJI's evaluator does not read `test_scoring_mechanism` (it sums passed-test
  scores and caps at `total_score`), and the premise `total_score ==
  max(test_scores)` is false for `FsF-F1-02MD` (total 1 = 0.5 + 0.5), so `max`
  scored it 0.5 instead of 1 and broke R/TS parity. The engine now sums and
  caps, matching F-UJI; a regression test pins `FsF-F1-02MD = 1` and the R/TS
  parity harness is back to 30/30.
- **`metadata_service_endpoint` / `metadata_service_type` were accepted and
  documented but never harvested** (`R/assess.R`, new
  `collect_metadata_service`). The endpoint is now fetched and parsed with the
  same format-gated collectors (schema.org via JSON-LD; others as XML then RDF),
  recording a `metadata_service` source; the docstring describes the real
  behavior.
- **Zero-total category percent could be `NaN`** (`R/scorer.R`). Guarded with a
  zero-denominator check (not reachable with bundled metrics, defensive).

## Not changed (verified NOT bugs)
Evaluator registration is complete for all 11 bundled versions incl. FRSM;
`levenshtein_ratio`/`token_sort_ratio` match the Python references; the
principle/category regex resolves FsF and FRSM ids correctly; merge priority,
`map_datacite` field guards, and metric-version normalization are correct.
