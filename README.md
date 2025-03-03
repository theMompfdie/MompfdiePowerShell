## **MompfdiePowerShell**  
*A collection of useful PowerShell scripts and automation tools*  

### 📜 **About**  
**MompfdiePowerShell** is a repository containing reusable PowerShell scripts for system administration, automation, and security tasks. The goal is to provide **efficient, modular, and well-documented** scripts that help streamline IT operations.  

🔹 **Current Focus:**  
✔️ Windows system automation  
✔️ Active Directory and authentication management  
✔️ Deployment & software updates  
✔️ Security and compliance tools  

---

## 🛠 **YubiKey Minidriver Auto-Update Script**
This PowerShell script automatically checks for the **latest version** of the **YubiKey Minidriver** in the NETLOGON share, **uninstalls the old version**, and installs the latest version if required.

### **Features**  
✅ Detects the current Active Directory domain dynamically  
✅ Searches for `.msi` installers in `\\<domain>\NETLOGON\YubiKey\`  
✅ Determines the **highest available version**  
✅ Compares it to the currently installed version  
✅ **Uninstalls old versions** before installing a new one  
✅ Runs **automatically with admin privileges**  

### **Requirements**  
- Windows PowerShell **5.1 or later**  
- Must be run **as Administrator**  
- The system must be **domain-joined** (or manually provide a valid UNC path)  
- The **NETLOGON** share must be accessible  

### **Usage**  
1️⃣ **Download the script** from the repository  
2️⃣ **Run it in PowerShell** (ensure execution policy allows it)  
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\Install-YubikeyMiniDriverSilent.ps1
   ```
3️⃣ The script will automatically:  
   - Detect the domain  
   - Find the latest MSI  
   - Uninstall the old version  
   - Install the new version  

---

## 📌 **Installation & Deployment**
For **automated deployment**, you can integrate this script into:  
- **GPO Logon Scripts** for domain-wide distribution  
- **Intune / SCCM** for enterprise deployments  
- **Task Scheduler** for periodic updates  

---

## 🔥 **Planned Features & Expansions**  
This repository will be **continuously updated** with useful PowerShell scripts, including:  
✔️ **Active Directory tools** (group membership audits, user management)  
✔️ **Security hardening scripts**  
✔️ **System monitoring & health checks**  
✔️ **Custom PowerShell modules**  

---

## 📜 **License**  
This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.  
⚠ **Disclaimer:** This software is provided **"as is"** without any warranty. Use at your own risk.

---

## 💡 **Contributing & Feedback**  
🚀 Have ideas, suggestions, or improvements? Feel free to **open an issue** or contribute to this repository!  
Let’s make **PowerShell scripting** more powerful together! 🔧💙  