function Install-SQLServerExpress 
{
<#
.SYNOPSIS
    Installs Microsoft SQL Server with customizable options.

.DESCRIPTION
    This function automates the installation of Microsoft SQL Server. It supports installation
    from either a downloaded executable or an ISO file. The function ensures prerequisites are met,
    verifies installation files, sets up SQL Server with specified configurations, and configures the
    TCP port settings.

    Author: Raimund Pließnig
    Version: 1.0.0.0

.PARAMETER SQLDownloadURL
    Specifies the URL to download the SQL Server installer.

.PARAMETER SQLExtractPath
    The local path where the downloaded installer will be extracted.

.PARAMETER SQLISOPath
    The path to a locally available SQL Server ISO file.

.PARAMETER SQLInstance
    Specifies the SQL Server instance name. Default is 'SQLEXPRESS'.

.PARAMETER SQLInstallDir
    Defines the directory where SQL Server will be installed.

.PARAMETER gMSA
    The group Managed Service Account for SQL Server service authentication.

.PARAMETER SQLSysAdmin
    The sysadmin account that will have administrative privileges on SQL Server.

.PARAMETER SQLMajorVersion
    The major version of SQL Server to install (e.g., 16 for SQL Server 2022).

.PARAMETER SQLFeatures
    Specifies the SQL Server features to install. Default is 'SQLEngine'.

.PARAMETER DisableUpdate
    Disables automatic updates during installation if set.

.PARAMETER DisableENU
    Disables the English language pack installation if set.

.PARAMETER EnableFileStream
    Enables FileStream feature if set.

.PARAMETER SQLPort
    The TCP port SQL Server should listen on. Default is 1433.

.PARAMETER InstanceDir
    Defines the instance root directory.

.PARAMETER SQLCollation
    Specifies the collation settings for the SQL Server instance.

.PARAMETER AGTSvcAccount
    Specifies the service account for SQL Server Agent.

.PARAMETER AGTSvcStartupType
    Defines the startup type for SQL Server Agent.

.PARAMETER ASSvcAccount
    Specifies the service account for Analysis Services.

.PARAMETER ASSvcStartupType
    Defines the startup type for Analysis Services.

.PARAMETER ASCollation
    Specifies the collation settings for Analysis Services.

.PARAMETER ASSysAdminAccounts
    Specifies the sysadmin accounts for Analysis Services.

.PARAMETER ASTempDir
    Specifies the temporary directory for Analysis Services.

.PARAMETER ASConfigDir
    Specifies the configuration directory for Analysis Services.

.PARAMETER ASDataDir
    Specifies the data directory for Analysis Services.

.PARAMETER ASLogDir
    Specifies the log directory for Analysis Services.

.PARAMETER BackupDir
    Specifies the backup directory for SQL Server.

.PARAMETER FTSvcAccount
    Specifies the service account for Full-Text Search.

.PARAMETER ISSvcAccount
    Specifies the service account for Integration Services.

.PARAMETER ISSvcStartupType
    Defines the startup type for Integration Services.

.PARAMETER ISFilePath
    Specifies the file path for Integration Services.

.PARAMETER RSSvcAccount
    Specifies the service account for Reporting Services.

.PARAMETER RSSvcStartupType
    Defines the startup type for Reporting Services.

.PARAMETER RSSQLInstance
    Specifies the SQL Server instance for Reporting Services.

.EXAMPLE
    Install-SQLServerExpress -SQLInstance 'MyInstance' -SQLDownloadURL 'https://example.com/sql.exe' -SQLExtractPath 'C:\Temp\SQLServer'

    This example installs SQL Server using a downloaded installer and extracts the setup files to 'C:\Temp\SQLServer'.

.EXAMPLE
    Install-SQLServerExpress -SQLISOPath 'D:\SQLServer.ISO' -SQLInstance 'MyInstance' -SQLPort 1444

    Installs SQL Server from an ISO file and configures the SQL Server instance to use TCP port 1444.

.EXAMPLE
    Install-SQLServerExpress -SQLInstance 'TestInstance' -SQLMajorVersion 15 -SQLPort 1450

    Installs SQL Server version 15 with a custom instance name and port 1450.

.EXAMPLE
    Install-SQLServerExpress -SQLInstance 'CustomInstance' -EnableFileStream -SQLFeatures 'SQLEngine,FullText'

    Installs SQL Server with FileStream enabled and additional features FullText Search.

.NOTES
    Author: Raimund Pließnig
    Version: 1.0.0.0
    Date Created: 2025-03-10

    Dependencies:
    - PowerShell 5.1 or newer
    - Administrator privileges required
    - Required Windows features: NetFx3, RSAT-AD-Tools

    Changelog:
    - Version 1.0.0.0: Initial release with full installation logic

    Usage Notes:
    - This script should not be modified once signed.
    - If a different SQL Server version is required, adjust the SQLMajorVersion parameter accordingly.
    - Ensure that the gMSA account exists before running the script.
    - The SQL Server port should be available before installation.

#>
  [CmdletBinding(DefaultParameterSetName = 'Download')]
  param (
    [Parameter(ParameterSetName = 'Download')]
    [string]$SQLDownloadURL = 'https://go.microsoft.com/fwlink/?linkid=2203572',

    [Parameter(ParameterSetName = 'Download')]
    [string]$SQLExtractPath = 'C:\Temp\SQLServer',

    [Parameter(ParameterSetName = 'ISO')]
    [string]$SQLISOPath,

    [string]$SQLInstance = 'MSSQLSERVER',
    [string]$SQLInstallDir = 'C:\Program Files\Microsoft SQL Server',
    [string]$gMSA = 'gMSA_SQLExp',
    [string]$SQLSysAdmin = 'Domain\Administrator',
    [int]$SQLMajorVersion = 16,
        
    [ValidateSet('SQLEngine', 'Replication', 'FullText', 'DQC', 'IS', 'MDS', 'PolyBase', 'R', 'SDK', 'SSMS', 'Tools', 'ADV_SSMS', 'Conn', 'BC', 'DREPLAY_CTLR', 'DREPLAY_CLT', 'BOL', 'SSB', 'SNAC', 'SQLWriter', 'DTS', 'SQL', 'All')]
    [string]$SQLFeatures = 'SQLEngine',
        
    [switch]$DisableUpdate,
    [switch]$DisableENU,
    [switch]$EnableFileStream,
    [int]$SQLPort = 1433,
        
    [string]$InstanceDir,
    [string]$SQLCollation,
    [string]$AGTSvcAccount,
    [string]$AGTSvcStartupType,
    [string]$ASSvcAccount,
    [string]$ASSvcStartupType,
    [string]$ASCollation,
    [string]$ASSysAdminAccounts,
    [string]$ASTempDir,
    [string]$ASConfigDir,
    [string]$ASDataDir,
    [string]$ASLogDir,
    [string]$BackupDir,
    [string]$FTSvcAccount,
    [string]$ISSvcAccount,
    [string]$ISSvcStartupType,
    [string]$ISFilePath,
    [string]$RSSvcAccount,
    [string]$RSSvcStartupType,
    [string]$RSSQLInstance
  )

  # Ensure script runs with administrator privileges
  #Requires -RunAsAdministrator

  # Check required Windows features
  $requiredFeatures = @('NetFx3', 'RSAT-AD-Tools')
  foreach ($feature in $requiredFeatures) {
    if (!(Get-WindowsFeature -Name $feature).Installed) {
      Write-Error -Message ('[ERROR] Required feature {0} is missing. Install it before running the script.' -f $feature)
      return
    }
  }

  # Check available disk space
  $freeSpaceGB = (Get-PSDrive -Name C).Free / 1GB
  if ($freeSpaceGB -lt 10) {
    Write-Error -Message ('[ERROR] Not enough disk space. At least 10GB required, but only {0}GB available.' -f [math]::Round($freeSpaceGB, 2))
    return
  }

  # Validate gMSA account existence
  if (!(Get-ADServiceAccount -Identity $gMSA -ErrorAction SilentlyContinue)) {
    Write-Error -Message ('[ERROR] The gMSA account {0} does not exist in Active Directory. Please create it first.' -f $gMSA)
    return
  }

  # Check SQL Port availability
  if (Test-NetConnection -Port $SQLPort -InformationLevel Quiet) {
    Write-Error -Message ('[ERROR] The specified SQL port {0} is already in use. Choose a different port.' -f $SQLPort)
    return
  }

  # Verify SQL Server installation file integrity
  if ($PSCmdlet.ParameterSetName -eq 'Download' -and !(Test-Path -Path "$SQLExtractPath\setup.exe")) {
    Write-Error -Message '[ERROR] SQL Server setup file is missing or corrupted. Please re-download.'
    return
  }

  Write-Host -Object '[INFO] SQL Server installation prerequisites passed. Proceeding with installation...' -ForegroundColor Green
  


  # Check if SQL Server is already installed
  if (Get-Service -Name ('MSSQL${0}' -f $SQLInstance) -ErrorAction SilentlyContinue) 
  {
    Write-Host -Object ('[INFO] SQL Server instance {0} is already installed. Exiting script.' -f $SQLInstance) -ForegroundColor Yellow
    return
  }

  Write-Host -Object '[INFO] Starting SQL Server installation...' -ForegroundColor Cyan

  $SetupPath = ''

  if ($PSCmdlet.ParameterSetName -eq 'Download') 
  {
    if (!(Test-Path -Path $SQLExtractPath)) 
    {
      $null = New-Item -ItemType Directory -Path $SQLExtractPath -Force
    }

    $SQLInstallPath = "$SQLExtractPath\SQLEXPR_x64_ENU.exe"

    if (!(Test-Path -Path $SQLInstallPath)) 
    {
      Write-Host -Object '[INFO] Downloading SQL Server...' -ForegroundColor Cyan
      try 
      {
        Invoke-WebRequest -Uri $SQLDownloadURL -OutFile $SQLInstallPath -ErrorAction Stop
      }
      catch 
      {
        Write-Error -Message ('[ERROR] Failed to download SQL Server: {0}' -f $_)
        return
      }
    }

    Write-Host -Object '[INFO] Extracting SQL Server setup files...' -ForegroundColor Cyan
    Start-Process -FilePath $SQLInstallPath -ArgumentList "/Q /X:$SQLExtractPath" -Wait -NoNewWindow
    $SetupPath = "$SQLExtractPath\setup.exe"
  }
  elseif ($PSCmdlet.ParameterSetName -eq 'ISO') 
  {
    Write-Host -Object ('[INFO] Mounting ISO file {0}...' -f $SQLISOPath) -ForegroundColor Cyan
    $mount = Mount-DiskImage -ImagePath $SQLISOPath -PassThru
    $driveLetter = ($mount | Get-Volume).DriveLetter + ':'
    $SetupPath = "$driveLetter\setup.exe"
  }

  # Prepare installation arguments
  $installArgs = @(
    '/Q', '/ACTION=Install', ('/INSTANCENAME={0}' -f $SQLInstance), 
    ('/FEATURES={0}' -f $SQLFeatures), '/IACCEPTSQLSERVERLICENSETERMS', 
    ('/SQLSVCACCOUNT="NT SERVICE\{0}"' -f $gMSA), 
    ('/SQLSYSADMINACCOUNTS="{0}"' -f $SQLSysAdmin), 
    '/TCPENABLED=1', ('/INSTALLSQLDATADIR="{0}"' -f $SQLInstallDir)
  )

  $optionalParams = @(
    'InstanceDir', 'SQLCollation', 'AGTSvcAccount', 'AGTSvcStartupType', 'ASSvcAccount', 'ASSvcStartupType',
    'ASCollation', 'ASSysAdminAccounts', 'ASTempDir', 'ASConfigDir', 'ASDataDir', 'ASLogDir', 'BackupDir',
    'FTSvcAccount', 'ISSvcAccount', 'ISSvcStartupType', 'ISFilePath', 'RSSvcAccount', 'RSSvcStartupType', 'RSSQLInstance'
  )

  foreach ($param in $optionalParams) {
    if (Get-Variable -Name $param -ValueOnly) {
      $installArgs += ('/{0}="{1}"' -f $param, (Get-Variable -Name $param -ValueOnly))
    }
  }

  if ($EnableFileStream) 
  {
    $installArgs += '/FILESTREAMLEVEL=3' 
  }
  if (-not $DisableENU) 
  {
    $installArgs += '/ENU'
  }
  if (-not $DisableUpdate) 
  {
    $installArgs += '/UpdateEnabled=1'
  }

  # Execute installation
  Write-Host -Object '[INFO] Installing SQL Server...' -ForegroundColor Cyan
  try 
  {
    Start-Process -FilePath $SetupPath -ArgumentList $installArgs -Wait -NoNewWindow
  }
  catch 
  {
    Write-Error -Message ('[ERROR] Installation failed: {0}' -f $_)
    return
  }

  Write-Host -Object '[INFO] SQL Server installation completed successfully!' -ForegroundColor Green

  # Verify and correct the SQL Server port
  $regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL$SQLMajorVersion.$SQLInstance\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
  if ((Get-ItemProperty -Path $regPath -Name TcpPort -ErrorAction SilentlyContinue).TcpPort -ne $SQLPort) 
  {
    Write-Host -Object ('[INFO] Setting SQL Server port to {0}...' -f $SQLPort) -ForegroundColor Cyan
    Set-ItemProperty -Path $regPath -Name TcpPort -Value $SQLPort
    Restart-Service -Name ('MSSQL${0}' -f $SQLInstance) -Force
  }

  # Unmount ISO if used
  if ($PSCmdlet.ParameterSetName -eq 'ISO') 
  {
    Dismount-DiskImage -ImagePath $SQLISOPath
    Write-Host -Object ('[INFO] Unmounted ISO file {0}.' -f $SQLISOPath) -ForegroundColor Cyan
  }
}

# SIG # Begin signature block
# MIIrcwYJKoZIhvcNAQcCoIIrZDCCK2ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcPtJt2rkSqJ2cm8cmJ+p85DI
# BhuggiT/MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0B
# AQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz
# 7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS
# 5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7
# bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfI
# SKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jH
# trHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14
# Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2
# h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt
# 6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPR
# iQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ER
# ElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4K
# Jpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRV
# HSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyh
# hyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO
# 0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo
# 8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++h
# UD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5x
# aiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJag
# AwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIw
# MzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCw
# zIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFz
# sbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ
# 7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7
# QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/teP
# c5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCY
# OjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9K
# oRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6
# dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM
# 1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbC
# dLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbEC
# AwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7Zv
# mKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI
# 2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/ty
# dBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVP
# ulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmB
# o1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc
# 6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3c
# HXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0d
# KNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZP
# J/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLe
# Mt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDy
# Divl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBrwwggSkoAMCAQICEAuuZrxaun+V
# h8b56QTjMwQwDQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJT
# QTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yNDA5MjYwMDAwMDBaFw0z
# NTExMjUyMzU5NTlaMEIxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEg
# MB4GA1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjQwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC+anOf9pUhq5Ywultt5lmjtej9kR8YxIg7apnjpcH9
# CjAgQxK+CMR0Rne/i+utMeV5bUlYYSuuM4vQngvQepVHVzNLO9RDnEXvPghCaft0
# djvKKO+hDu6ObS7rJcXa/UKvNminKQPTv/1+kBPgHGlP28mgmoCw/xi6FG9+Un1h
# 4eN6zh926SxMe6We2r1Z6VFZj75MU/HNmtsgtFjKfITLutLWUdAoWle+jYZ49+wx
# GE1/UXjWfISDmHuI5e/6+NfQrxGFSKx+rDdNMsePW6FLrphfYtk/FLihp/feun0e
# V+pIF496OVh4R1TvjQYpAztJpVIfdNsEvxHofBf1BWkadc+Up0Th8EifkEEWdX4r
# A/FE1Q0rqViTbLVZIqi6viEk3RIySho1XyHLIAOJfXG5PEppc3XYeBH7xa6VTZ3r
# OHNeiYnY+V4j1XbJ+Z9dI8ZhqcaDHOoj5KGg4YuiYx3eYm33aebsyF6eD9MF5IDb
# PgjvwmnAalNEeJPvIeoGJXaeBQjIK13SlnzODdLtuThALhGtyconcVuPI8AaiCai
# JnfdzUcb3dWnqUnjXkRFwLtsVAxFvGqsxUA2Jq/WTjbnNjIUzIs3ITVC6VBKAOlb
# 2u29Vwgfta8b2ypi6n2PzP0nVepsFk8nlcuWfyZLzBaZ0MucEdeBiXL+nUOGhCjl
# +QIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYD
# VR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZI
# AYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQW
# BBSfVywDdw4oFZBmpWNe7k+SH3agWzBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2
# VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hB
# MjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQA9rR4fdplb
# 4ziEEkfZQ5H2EdubTggd0ShPz9Pce4FLJl6reNKLkZd5Y/vEIqFWKt4oKcKz7wZm
# Xa5VgW9B76k9NJxUl4JlKwyjUkKhk3aYx7D8vi2mpU1tKlY71AYXB8wTLrQeh83p
# XnWwwsxc1Mt+FWqz57yFq6laICtKjPICYYf/qgxACHTvypGHrC8k1TqCeHk6u4I/
# VBQC9VK7iSpU5wlWjNlHlFFv/M93748YTeoXU/fFa9hWJQkuzG2+B7+bMDvmgF8V
# lJt1qQcl7YFUMYgZU1WM6nyw23vT6QSgwX5Pq2m0xQ2V6FJHu8z4LXe/371k5QrN
# 9FQBhLLISZi2yemW0P8ZZfx4zvSWzVXpAb9k4Hpvpi6bUe8iK6WonUSV6yPlMwer
# wJZP/Gtbu3CKldMnn+LmmRTkTXpFIEB06nXZrDwhCGED+8RsWQSIXZpuG4WLFQOh
# tloDRWGoCwwc6ZpPddOFkM2LlTbMcqFSzm4cd0boGhBq7vkqI1uHRz6Fq1IX7TaR
# QuR+0BGOzISkcqwXu7nMpFu3mgrlgbAW+BzikRVQ3K2YHcGkiKjA4gi4OA/kz1YC
# sdhIBHXqBzR0/Zd2QwQ/l4Gxftt/8wY3grcc/nS//TVkej9nmUYu83BDtccHHXKi
# bMs/yXHhDXNkoPIdynhVAku7aRZOwqw6pDCCB38wggVnoAMCAQICE1kAAAERkHam
# 4RDNuicAAAAAAREwDQYJKoZIhvcNAQELBQAwgf8xCzAJBgNVBAYTAkFUMRUwEwYD
# VQQIEwxMb3dlckF1c3RyaWExFzAVBgNVBAcTDktsb3N0ZXJuZXVidXJnMRUwEwYD
# VQQKEwxEaWVNb21wZmRpZXMxIDAeBgNVBAsTF0ZvciBhdXRob3JpemVkIHVzZSBv
# bmx5MSgwJgYDVQQLEx9DZXJ0aWZpY2F0aW9uIFNlcnZpY2VzIERpdmlzaW9uMTgw
# NgYDVQQDEy9EaWUgTW9tcGZkaWVzIFN1Ym9yZGluYXRlIENlcnRpZmljYXRlIEF1
# dGhvcml0eTEjMCEGCSqGSIb3DQEJARYUcGtpQGRpZS1tb21wZmRpZXMuYXQwHhcN
# MjQwNTIwMTUwMjMzWhcNMjUwNTIwMTUwMjMzWjCBsDEVMBMGCgmSJomT8ixkARkW
# BWxvY2FsMRgwFgYKCZImiZPyLGQBGRYIbW9tcGZkaWUxFTATBgNVBAsTDERpZU1v
# bXBmZGllczEOMAwGA1UECxMFVGllcjIxEDAOBgNVBAsTB1QyLVVzZXIxGjAYBgNV
# BAMMEVJhaW11bmQgUGxpZcOfbmlnMSgwJgYJKoZIhvcNAQkBFhltb21wZmRpZUBk
# aWUtbW9tcGZkaWVzLmF0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# vKjT2wve7Ufj/2atyS9Z4LNcpGTAdKF4uAB8sp+NSmlOs1zpKC571WujCriHbiUO
# f8UMzOWyKwtqLyGeKIdkJH8vKkq7nc0MhZVUXXvstYbn/RQSt66t71AXftgHxemI
# czfTVmXNZP2kIMwnxmwFDGmlifoCs1N0eWUjIRlKc1hdMdVO9M7KL7u/yNyWBEnd
# kZOUTMbrLDXxHssymAq6UTa37WKm8Hm9QlXuA2WDbWknTbyBpz2eyjnaNLycz24j
# hnwJhlxh2NKxytpWNPmEWVp+7j2nDQ5G0tS8ntP0KRolYtkpbLVj81mXRI+lFCko
# LZKyWNdo1ylMun53Cd5/xQIDAQABo4ICPzCCAjswPAYJKwYBBAGCNxUHBC8wLQYl
# KwYBBAGCNxUIgYaOU97sCYXlhTuCk8Bahd/zKoEk7Phih4CsQwIBZAIBAjATBgNV
# HSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwGwYJKwYBBAGCNxUKBA4w
# DDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUIMmxL5bUsiTubWpm3qx5BlTCG9gwHwYD
# VR0jBBgwFoAUYzqCNokgjeDVrILuNGu1Ja/CjVQwcwYDVR0fBGwwajBooGagZIZi
# aHR0cDovL3BraS5kaWUtbW9tcGZkaWVzLmF0L0NlcnRFbnJvbGwvRGllJTIwTW9t
# cGZkaWVzJTIwU3Vib3JkaW5hdGUlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eS5j
# cmwwfgYIKwYBBQUHAQEEcjBwMG4GCCsGAQUFBzAChmJodHRwOi8vcGtpLmRpZS1t
# b21wZmRpZXMuYXQvQ2VydEVucm9sbC9EaWUlMjBNb21wZmRpZXMlMjBTdWJvcmRp
# bmF0ZSUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5LmNydDA0BgNVHREELTAroCkG
# CisGAQQBgjcUAgOgGwwZTW9tcGZkaWVAZGllLW1vbXBmZGllcy5hdDBOBgkrBgEE
# AYI3GQIEQTA/oD0GCisGAQQBgjcZAgGgLwQtUy0xLTUtMjEtMjIwNjMwNzI1OS05
# OTMxNjA4NzktMTQ5MzY4OTk1My0xMTA1MA0GCSqGSIb3DQEBCwUAA4ICAQCLNVLP
# vdIvfTwwRJkgVnryc5lCpHXdVz2hIP4ZMN4O9rWkVxJMrOYPaTs2EIjQQN2Rv7+6
# fIiczJMGiBis6Hn/R+Am0XYxQGnGfCJwegpQlGlaD6oCjWNohzKEFN7bgWorNU6J
# XD2gQXwI0PvPnPBGaB6KnyyehZjw8c5BI91WhyxjIEoIyS0f+D58hu2mgRLjlu6G
# d2WcfPtlxQru0ZJFoWwhFwa3ipqN+dsKNFv8d1CsNrqq/vJ/NDsI4QqpQJWqN+6A
# AfeMGXPNt0SfD6mpJ9ji9DwbhKoVYQvZSlQHioT2TagEAoubAaMrsPCDsU90oZxC
# PHDHBByghEsThBnZm8uOr4vrvOPRXA1YSZkjVo6CERbtxBmuStWDqjeVKSE1JU3d
# wcmAhqLHAxDQVEZfmNNWinp+Yq5b+tBKe+iC2Nog7r/sLnRxlCxnMg1k7qKlhy1K
# QEjuRjhTP+SiflC+Y45xExMJLKYL+m0IhIvi87+Q05dCLq6zcsgQ3l/9RKyH9TDQ
# mYjqmi0mEGLtlgark4c8jsTxZTN9v06/wAy6szVCZ9HuHZ6zQlw73Nb4JU+gNKJ2
# T7LiaMSBqw1h4U3Kn3ye1ofHwQXeCZ+iMRgQUypGQbRyPyhxBS3JHYJ3ZaQ65249
# 0N54lE4bUQ47m9SHrpRUfnkCzubc4X8HKlGmFDCCCnUwgghdoAMCAQICE2oAAAAE
# LA49J5ScAx8AAAAAAAQwDQYJKoZIhvcNAQELBQAwgfgxIzAhBgkqhkiG9w0BCQEW
# FHBraUBkaWUtbW9tcGZkaWVzLmF0MQswCQYDVQQGEwJBVDEVMBMGA1UECBMMTG93
# ZXJBdXN0cmlhMRcwFQYDVQQHEw5LbG9zdGVybmV1YnVyZzEVMBMGA1UEChMMRGll
# TW9tcGZkaWVzMSAwHgYDVQQLExdGb3IgYXV0aG9yaXplZCB1c2Ugb25seTEoMCYG
# A1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjExMC8GA1UEAxMo
# RGllIE1vbXBmZGllcyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0yMDAy
# MjMxMzQxNDlaFw0zMDAyMjMxMzUxNDlaMIH/MQswCQYDVQQGEwJBVDEVMBMGA1UE
# CBMMTG93ZXJBdXN0cmlhMRcwFQYDVQQHEw5LbG9zdGVybmV1YnVyZzEVMBMGA1UE
# ChMMRGllTW9tcGZkaWVzMSAwHgYDVQQLExdGb3IgYXV0aG9yaXplZCB1c2Ugb25s
# eTEoMCYGA1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYG
# A1UEAxMvRGllIE1vbXBmZGllcyBTdWJvcmRpbmF0ZSBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkxIzAhBgkqhkiG9w0BCQEWFHBraUBkaWUtbW9tcGZkaWVzLmF0MIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5jBry0q/1zH5VNOt8L/IbIemAlCc
# nf7tDpxERd7pVrWV0OGSpD7FIL8RxGiN/bmKi7gEh1cxPC7Be6bgsZOfVuDE04kt
# QzF6IaUFoiUorRb1B5fL0O7Phr4xBPh79AiV8Qui2Umax9pHUg1eIve1U21bnq/6
# 3pxkHYZMV3noGUxJclfAKQo6eM4WpK7LFGZ4JL1ngZGgW75brkuJ6JKEl3GmlM1V
# vuaYhgGjB785KYb2E19iW/gjpzNjnlhdy5e8u9YBJ4iAE8xLUVRR4B6m41uQAr2R
# d9ukAfJeVbBd5Fx4RboNvCbAoZt3fRq7RYPUGd1QxvZhANauI2JGmPeflXvqFVfX
# NMt7RMtNYo9nWQ02YUFWHnZpOvmIofN0gZEi4IckgtCr7iHEYMiN54Ah4okC3fk2
# 9ip7QJMkJrxbqEKsRzBerHnuICAQl2Yp/s7cfIGUYX5e1AQ+2Tdnr1c1H+SdD2vo
# SSBYL5LpMv85RD6JfvZAKHeL47/dKmapvOU3EavJiAdkBjF1j8I1heqD37S2BKEP
# FCcf1JOOG0RDT54huUdFYMmQ3LD4GZZ1+tPhywB9S7TD2CSkkzs+6EtUJjjljgPU
# GL4ZxMPBABwfIiwhdYi1A/n4ES+9Ko2CWOP8JKXFoT68i9njFoKVEbmFYVq+4/fl
# zZUUGntQKiMcbJ0CAwEAAaOCA+0wggPpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1Ud
# DgQWBBRjOoI2iSCN4NWsgu40a7Ulr8KNVDCCAnAGA1UdIASCAmcwggJjMIICXwYI
# KwYBBAGDrmwwggJRMIICBgYIKwYBBQUHAgIwggH4HoIB9ABUAGgAaQBzACAARQBu
# AHQAZQByAHAAcgBpAHMAZQAgAEMAZQByAHQAaQBmAGkAYwBhAHQAaQBvAG4AIABB
# AHUAdABoAG8AcgBpAHQAeQAgAGkAcwAgAGEAbgAgAGkAbgB0AGUAcgBuAGEAbAAg
# AHIAZQBzAG8AdQByAGMAZQAuACAAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAcwAg
# AGkAcwBzAHUAZQBkACAAYgB5ACAAdABoAGkAcwAgAEMAQQAgAGEAcgBlACAAZgBv
# AHIAIABpAG4AdABlAHIAbgBhAGwAIAB1AHMAZQAgAG8AbgBsAHkALgAgACAARgBv
# AHIAIABtAG8AcgBlACAAaQBuAGYAbwByAG0AYQB0AGkAbwBuACwAIABwAGwAZQBh
# AHMAZQAgAHIAZQBmAGUAcgAgAHQAbwAgAHQAaABlACAAQwBlAHIAdABpAGYAaQBj
# AGEAdABpAG8AbgAgAFAAcgBhAGMAdABpAGMAZQAgAFMAdABhAHQAZQBtAGUAbgB0
# ACAAYQB0ACAAaAB0AHQAcAA6AC8ALwBwAGsAaQAuAGQAaQBlAC0AbQBvAG0AcABm
# AGQAaQBlAHMALgBhAHQALwBDAGUAcgB0AEUAbgByAG8AbABsAC8AYwBwAHMALgBo
# AHQAbQBsMEUGCCsGAQUFBwIBFjlodHRwOi8vcGtpLmRpZS1tb21wZmRpZXMuYXQv
# Q2VydEVucm9sbC9zdWJMZWdhbFBvbGljeS50eHQwGQYJKwYBBAGCNxQCBAweCgBT
# AHUAYgBDAEEwCwYDVR0PBAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j
# BBgwFoAUtQCEHja4hhtU3thT5mGViZ3GJF4wbAYDVR0fBGUwYzBhoF+gXYZbaHR0
# cDovL3BraS5kaWUtbW9tcGZkaWVzLmF0L0NlcnRFbnJvbGwvRGllJTIwTW9tcGZk
# aWVzJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5LmNybDB3BggrBgEF
# BQcBAQRrMGkwZwYIKwYBBQUHMAKGW2h0dHA6Ly9wa2kuZGllLW1vbXBmZGllcy5h
# dC9DZXJ0RW5yb2xsL0RpZSUyME1vbXBmZGllcyUyMFJvb3QlMjBDZXJ0aWZpY2F0
# ZSUyMEF1dGhvcml0eS5jcnQwDQYJKoZIhvcNAQELBQADggIBAKg8cPpnjzLmbh1Z
# innzwb7ro5HxzeYss9tO4NZJcHOSOc8vHLtCpQNhbaLj3t1wN4UJtY9SYx8PdGdm
# z2OvjqxCHlab6GXaFB2zVLBvF4HL9GXFoa2WaD1/sjJihzbSWLZ5armx7siq0rAZ
# QfN0/cWqxoMnpCCWKhUOkBlgpZXjIjaMJAhE7kDomLbTzq7T1PgQp6PiJn0iLVxn
# aQYRQEGH2jOIBr8IOq7XiFIquoFlJbpr4VeNEIMxmUqaptHX+EEZW3APDQ0ab5si
# P+eFnExi016Ijjmd/IyUviH0Kvqiua0Y1WAStWQUXeIgoOGCPVNLk+UJwcW9tWD8
# hWCFT9f5cN9iXX3x/pgUdZlgFaSXmtqRfvxbwl0a20K0yZoM8YKAAWFrNe2ZbUNU
# XVouxt+UdXGSrGxi4p+QQGUoQa/KeszAP05CKU3aTUj2JlyaFkVSWXabMChaw8tf
# fvf3/a0OJTqb41Qic7iEpklhWSUD1rZwniYNlMAiwFE82Yhv9Lmu/+I7FdhJJO/C
# DVN4P3HVihE2ZmvrzA5MferPlOo6E8GSDIbeAGuZm7UJ8Apz4vxJ/JLHooRmdGv8
# hkP30zRDqGyWMPFxfuMMCpj8tPBRiq0LoSKs5k6gLUHuHrpJuWWwWeA91BesLTKU
# pdgnd2cRje2dHImzGnIXT4DZBZ2FMYIF3jCCBdoCAQEwggEXMIH/MQswCQYDVQQG
# EwJBVDEVMBMGA1UECBMMTG93ZXJBdXN0cmlhMRcwFQYDVQQHEw5LbG9zdGVybmV1
# YnVyZzEVMBMGA1UEChMMRGllTW9tcGZkaWVzMSAwHgYDVQQLExdGb3IgYXV0aG9y
# aXplZCB1c2Ugb25seTEoMCYGA1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBE
# aXZpc2lvbjE4MDYGA1UEAxMvRGllIE1vbXBmZGllcyBTdWJvcmRpbmF0ZSBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkxIzAhBgkqhkiG9w0BCQEWFHBraUBkaWUtbW9tcGZk
# aWVzLmF0AhNZAAABEZB2puEQzbonAAAAAAERMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR2cKT3
# esM1mhV+DTlcB2A7xLvuRTANBgkqhkiG9w0BAQEFAASCAQAmyE2xOYv6MopMUH/Z
# 9jvWsU2c+JXlL2zhnzqDLA0YwAQ8ZSfwJounKy5HCmOrmq+k1bByVD3YCaYxY6mo
# W+vWGBYpwh7BIHLxLl6CunUDUDCqf14GkTQCj1z8OGqkGRYgx6cK/MEGxqaFi4lQ
# lkI5pvkGztYVWTvhdihG2Owh/n+e//2ib/mDlenFoWgyINFtpAVqv/cZjllRoCuj
# DrLe+She0frQR5dp9HRwJ52GDGy4I+VKrELW6cAn0hJOcqJgDO0Xm9ANJ5qkVL3o
# UWorbsd5CecxN6j6q7WrHya7peW3pBrQv/E+NrbHvkoOD+oABvcAiJ3jkQ63UfGU
# 3xZeoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQC65mvFq6
# f5WHxvnpBOMzBDANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG
# 9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI1MDMxMDIxNTAzNlowLwYJKoZIhvcNAQkE
# MSIEIFoN97aCkpXZGoQNTovIqx/IGFPjXnh1YKxhKuA7VW9nMA0GCSqGSIb3DQEB
# AQUABIICAGCIOtjc9UJgfI/u4QW+Hj4n+s5OJH8AVDD6SXzWH7Mu6xP38BT0oOFt
# imy+q0YEnAcMl+Hn7eDo2p57+1YzOq0yC2Du84NserKU3kdAzzLmp5ICkRFOtuz3
# n3k3Kd6CDu5WzqFBiuc6DKosD7mQUWKM79QsEXsBirak3F5DGt3n0AZZnNGgn6mt
# DE3tDEixcR6MLkNGBCt9zbgFWiPSuumRrVtBECHlmKwOaJfvF7xeWUT7j/+cEDdI
# 0oY5n1eqgLURKauOXF3CLj8kYD1pmz6Op9+7gNfsaDiSK6VnoTgmNoDyqZMzk4eQ
# vvxGcf2mBLNvEYxTdVcBEMj5elIdE8IxxkNLKTdxj2DESBnrl1C3iP3VxApSsgGr
# Ek4m9izyVXjBi+nqIZIaVW6AD2OJn5gScOy08jEGEhLQBreaxYuvPsmpgZLzA9bi
# 8diHRQLhY3ghgJxhYCdYGaAB2Qwc0ujFt0BPlHUyjD9POmDFo5MHFXLxvrf9+S7F
# Y0er3c3d+i7UPwqyZg7YlCaRvBYRQFfu9hUAmorcfiRaQTKMpwyNnbb12tt2Bi5t
# r9rOemBgPmnNx6Nl1F0Nu2k9J2T+jhND7ksuWqG/LGmj2BhUYCBeb4lWErP3uW/a
# hqSgjFpEzxothQWwYVKJUYLckHPkf+A9HcBMF/de6P2WvrVzsS+4
# SIG # End signature block
