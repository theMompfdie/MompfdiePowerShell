# ADCS-Operations

This folder contains standalone PowerShell scripts that support OpenSSL-based certificate operations
and Microsoft Active Directory Certificate Services (ADCS) integration.

Each script serves a modular purpose to generate certificates, submit CSRs, retrieve issued certificates,
and package them into secure .pfx files.

---

## 📦 Included Scripts

### 1. `New-OpenSslCnfFile.ps1`
Generates an OpenSSL-compatible `.cnf` file for use when creating a CSR.

**Example:**
```powershell
New-OpenSslCnfFile -CommonName 'web01.example.com' -SubjectAltNames @('DNS:web01.example.com','IP:192.168.0.100')
```

---

### 2. `New-OpenSslKeyAndCsr.ps1`
Creates a 4096-bit RSA private key and a corresponding CSR using OpenSSL.

**Example:**
```powershell
New-OpenSslKeyAndCsr -ConfigPath 'C:\Certs\web01.cnf'
```

---

### 3. `Request-CertificateViaCertreq.ps1`
Submits a CSR to an internal Microsoft CA using `certreq.exe`. Handles both issued and pending certificate states. Pending requests are tracked via a `.request.json` file.

**Example:**
```powershell
Request-CertificateViaCertreq -CsrPath 'C:\Certs\web01.csr' -CAConfig 'CA01\My-CA' -CertTemplate 'WebServer'
```

---

### 4. `Retrieve-CertificateFromRequestJson.ps1`
Retrieves a certificate from the CA using the previously saved `.request.json`. Detects pending status and handles issued certificates.

**Example:**
```powershell
Retrieve-CertificateFromRequestJson -RequestJsonPath 'C:\Certs\web01.request.json'
```

---

### 5. `ConvertTo-PfxBundle.ps1`
Combines the private key, certificate, and chain into a password-protected `.pfx` file using OpenSSL.

**Example:**
```powershell
$pw = ConvertTo-SecureString 'SuperSecret123' -AsPlainText -Force
ConvertTo-PfxBundle -KeyPath 'web01.key' -CertificatePath 'web01.cer' -ChainPath 'chain.crt' -PfxPassword $pw
```

---

## 🔐 Requirements
- OpenSSL (Windows build)
- PowerShell 5.1 or PowerShell 7+
- Access to an enterprise or standalone Microsoft CA (for certreq usage)

## ✅ Purpose
This set is designed for automated, repeatable certificate operations using
OpenSSL and ADCS, without requiring complex tooling or long-term state.

> No organization-specific settings are included. All paths, names, and defaults are customizable.

---

## 🧾 License
MIT License — feel free to reuse or adapt with attribution.
