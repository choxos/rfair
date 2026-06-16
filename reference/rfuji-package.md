# rfuji: Assess the FAIRness of Research Data Objects

rfuji is a native R implementation of the F-UJI (FAIRsFAIR Research Data
Object Assessment) metrics. Given a persistent identifier or URL, it
resolves the object, harvests metadata from its landing page and from
registries such as DataCite, and scores the result against the FAIRsFAIR
metrics. Unlike the original rfuji client, this version performs the
assessment entirely in R and does not require a running F-UJI server.

## Details

The main entry point is
[`assess_fair()`](https://choxos.github.io/rfuji/reference/assess_fair.md).
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

- Steffen Neumann <sneumann@ipb-halle.de> (Author of the original rfuji
  F-UJI API client)

Other contributors:

- PANGAEA (Copyright holder of the F-UJI service whose metrics rfuji
  reimplements) \[copyright holder\]
