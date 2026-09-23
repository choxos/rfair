# rfair: Assess the FAIRness of Research Data Objects and Software

rfair is a native R implementation of the F-UJI (FAIRsFAIR Research Data
Object Assessment) metrics and the FRSM (FAIR for Research Software)
metrics. Given a persistent identifier, URL, or code repository, it
resolves the object, harvests metadata from its landing page, registries
such as DataCite, and code forges, and scores the result against the
chosen metrics. rfair began as a fork of the rfuji F-UJI API client;
unlike that client, it performs the assessment entirely in R and does
not require a running F-UJI server.

## Details

The main entry point is
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).
See the package vignettes and <https://choxos.github.io/rfair/> for
details.

## See also

Useful links:

- <https://github.com/choxos/rfair>

- <https://choxos.github.io/rfair/>

- Report bugs at <https://github.com/choxos/rfair/issues>

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
