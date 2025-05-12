# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] - 2025-05-12
### Added
- ADCS-Operations toolset for OpenSSL and Microsoft CA integration
- `New-OpenSslCnfFile.ps1` to generate .cnf files for CSRs
- `New-OpenSslKeyAndCsr.ps1` to create private key and CSR
- `Request-CertificateViaCertreq.ps1` to submit CSRs to a Microsoft CA
- `Retrieve-CertificateFromRequestJson.ps1` to retrieve issued certs
- `ConvertTo-PfxBundle.ps1` to build secure .pfx bundles
- `README.md` with examples and script descriptions

---

## [v1.0.0] - 2025-03-12
### Added
- Initial public snapshot of helper functions and GitHub automation
