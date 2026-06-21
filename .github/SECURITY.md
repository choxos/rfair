# Security Policy

## Supported versions

Security reports are accepted for the current `main` branch and the latest
released version of `rfair`.

| Version | Supported |
| --- | --- |
| Latest release | Yes |
| `main` | Yes |
| Older releases | Best effort |

## Reporting a vulnerability

Please do not report security vulnerabilities in public issues.

Preferred reporting path:

1. Use GitHub's private vulnerability reporting or security advisory workflow if
   it is available for this repository.
2. If that is not available, email the maintainer at
   <a.sofimahmudi@gmail.com>.

Include:

- A description of the vulnerability.
- Steps to reproduce it.
- The affected package version or commit.
- Whether the issue involves network metadata harvesting, file parsing, the
  Shiny app, the Plumber API, or generated outputs.
- Any known mitigations.

The maintainer will acknowledge reports as soon as practical, investigate the
issue, and coordinate a fix and disclosure timeline. Public disclosure should
wait until a fix or mitigation is available, unless there is an overriding user
safety reason to disclose sooner.

## Scope

In scope:

- Code execution, injection, path traversal, or unsafe file handling in package
  code, the Shiny app, or the Plumber API scaffold.
- Unsafe handling of untrusted metadata, URLs, RDF, JSON-LD, XML, or archives.
- Exposure of credentials, tokens, private data, or restricted metadata.

Out of scope:

- Vulnerabilities only present in third-party services assessed by `rfair`.
- General FAIR score disagreements without a security impact.
- Spam, social-engineering campaigns, or denial-of-service reports that do not
  identify a package vulnerability.
