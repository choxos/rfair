# rfair: Assess the FAIRness of Research Data Objects

rfair is a native R implementation of the F-UJI (FAIRsFAIR Research Data
Object Assessment) metrics. Given a persistent identifier or URL, it
resolves the object, harvests metadata from its landing page and from
registries such as DataCite, and scores the result against the FAIRsFAIR
metrics. rfair began as a fork of the rfuji F-UJI API client; unlike
that client, it performs the assessment entirely in R and does not
require a running F-UJI server.

## Details

The main entry point is
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).
See the package vignettes and <https://choxos.github.io/rfuji/> for
details.

## See also

Useful links:

- <https://github.com/choxos/rfuji>

- <https://choxos.github.io/rfuji/>

- Report bugs at <https://github.com/choxos/rfuji/issues>

## Author

**Maintainer**: Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>
([ORCID](https://orcid.org/0000-0001-6829-0823))

Authors:

- Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-6829-0823))

Other contributors:

- Steffen Neumann <sneumann@ipb-halle.de> (Author of the original rfuji
  F-UJI API client that rfair grew from) \[contributor\]

- PANGAEA (Copyright holder of the F-UJI service whose metrics rfair
  reimplements) \[copyright holder\]
