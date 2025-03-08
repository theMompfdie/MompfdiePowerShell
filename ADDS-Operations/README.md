# New-gMSAccount PowerShell Function

## 📌 Overview
`New-gMSAccount` is a PowerShell function that simplifies the creation and management of **Group Managed Service Accounts (gMSA)** in Active Directory.

It supports:
- **Automated security group creation** for each gMSA
- **Kerberos encryption settings** (default: AES256)
- **Service Principal Name (SPN) registration** and delegation
- **Custom password rotation intervals**
- **WhatIf support** to test commands before execution

## ⚙️ Prerequisites
- Windows Server with **Active Directory PowerShell Module**
- Appropriate permissions to create gMSAs and modify AD security groups
- Active Directory schema supporting Managed Service Accounts

## 🚀 Installation
Clone this repository or download the script and import it into PowerShell:
```powershell
Import-Module .\New-gMSAccount.ps1
```

## 💡 Usage Examples
### ▶️ Basic gMSA Creation
```powershell
New-gMSAccount -AccountName 'gMSA_SQL'
```

### ▶️ gMSA with Security Group and SPNs
```powershell
New-gMSAccount -AccountName 'gMSA_Web' -AddMembersToGroup 'WebAdmins' -ServicePrincipalNames 'HTTP/webserver.domain.com'
```

### ▶️ Run in Simulation Mode (WhatIf)
```powershell
New-gMSAccount -AccountName 'gMSA_Test' -WhatIf
```

### ▶️ Custom Password Rotation Interval & Kerberos Settings
```powershell
New-gMSAccount -AccountName 'gMSA_Custom' -PasswordIntervalDays 30 -KerbAuthTypes AES256,AES128
```

## 🔧 Parameters
| Parameter | Description |
|-----------|-------------|
| `-AccountName` | **(Required)** The name of the gMSA (max 15 characters). |
| `-AccountTargetPath` | AD path where the gMSA will be created. Defaults to `CN=Managed Service Accounts,<domain>`. |
| `-GroupTargetPath` | AD path where the security group will be created. Defaults to `Users` container. |
| `-DNSSuffix` | DNS suffix for the gMSA. Defaults to current domain’s root. |
| `-KerbAuthTypes` | Kerberos encryption types (`AES256` by default). |
| `-PasswordIntervalDays` | Managed password update interval (default: 7 days). |
| `-AddMembersToGroup` | List of AD objects to add to the security group. |
| `-ServicePrincipalNames` | List of SPNs to be registered (enables delegation). |
| `-Description` | Optional description for the gMSA account. |
| `-DisplayName` | Optional display name for the gMSA account. |
| `-Enabled` | Boolean flag to enable/disable the gMSA (default: `$true`). |
| `-WhatIf` | **Simulates execution** without making changes. |

## ⚠️ Notes
- SPNs must be unique and properly formatted (e.g., `HTTP/webserver.domain.com`).
- If delegation is required, ensure the necessary permissions are assigned in Active Directory.

## 📜 License
This script is provided under the **MIT License**. Feel free to use and modify it as needed.

## 👨‍💻 Author
**Raimund Pließnig**