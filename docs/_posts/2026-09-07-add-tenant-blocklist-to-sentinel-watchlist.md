---
title: Sync the tenant block list to a Microsoft Sentinel watchlist
updated: 2026-10-27
created: 2026-09-07
layout: post
description: Use an Azure Automation runbook to copy the Microsoft Defender tenant block list into a Sentinel watchlist so you can use it in hunting queries.
date: 2026-09-06
categories:
  - guide
tags:
  - guide
  - sentinel
  - watchlist
  - tenant allow block list
---

There is no native link between the Microsoft Defender Tenant Allow/Block List (TABL) and Microsoft Sentinel. Copying the block entries into a Sentinel watchlist lets you use them in advanced hunting, for example to find mail that arrived from a sender before you blocked them, or to exclude already-blocked items from your results.

This guide covers block entries only. The same approach works for allow entries if you extend the script.

## Overview

1. Create a template watchlist (optional)
2. Register an application for Exchange Online
3. Give the application a role in Exchange Online
4. Create an automation account with a managed identity
5. Create a key vault and certificate, and link the certificate to the application
6. Create a runtime environment in the automation account
7. Create the runbook
8. Link the runbook to a schedule
9. Use the watchlist in advanced hunting

Throughout this guide the watchlist alias is `tablSync`. If you choose a different alias, use it consistently in the runbook parameters and your queries.

## 1. Create a template watchlist (optional)

The runbook replaces the watchlist on every run, so this step isn't required. Creating it first lets you write and test queries before the first sync.

1. Save the following as `tempfile.csv`:
   ```csv
   blockedItem,Type,Value,ExpirationDate,Notes
   dummyEntry,dummyEntry,dummyEntry,dummyEntry,dummyEntry
   ```
2. In the [Microsoft Defender portal](https://security.microsoft.com), expand **Microsoft Sentinel**, then **Configuration**, and select **Watchlist**.
3. Create a new watchlist:
   - Name: `tablSync`
   - Description: anything that will help you recognise it
   - Alias: `tablSync`
4. In the **Source** section:
   - Source type: `Local file`
   - File type: `CSV file with a header`
   - Number of lines before row with headings: `0`
   - Upload `tempfile.csv`
   - Search key: `blockedItem`
5. Select **Review + create**, then **Create**.

## 2. Register an application for Exchange Online

The runbook reads the block list through Exchange Online PowerShell, which needs an application identity.

1. With a suitably privileged Entra role, go to **App registrations** and select **New registration**.
   ![Registering the application](/assets/images/ba1388cdf1bf1ac98c67281a2f485aeb.png)
2. Enter a name for the application and choose **Single tenant only**.
3. Select **Register**.
4. In the new registration, go to **API permissions** and add the application permission **Office 365 Exchange Online** › `Exchange.ManageAsApp`.
5. Grant admin consent for the permission.

## 3. Give the application a role in Exchange Online

Assign the **View-Only Configuration** role in Exchange Online to the application you have just registered. This allows it to read the Tenant Allow/Block List without being able to change it.

## 4. Create an automation account with a managed identity

1. In the Azure portal, go to **Automation Accounts** and create a new account.
2. Enter the **Subscription**, **Resource group**, **Automation account name** and **Region**.
3. Select **Review + create**, then **Create**.
4. In the new automation account, go to **Account settings** › **Identity** and turn on the **System assigned** managed identity. The runbook uses this identity to sign in to Azure.
5. Go to the resource group (or Log Analytics workspace) that holds your Sentinel workspace, open **Access control (IAM)** and assign the **Microsoft Sentinel Contributor** role to the automation account's managed identity. This allows the runbook to create and replace the watchlist.

## 5. Create a key vault and certificate

1. In the Azure portal, go to **Key vaults** and create a new key vault, using the same subscription and resource group as the automation account.
2. Use the **Standard** pricing tier and the **Azure role-based access control** permission model.
3. Select **Review + create**, then **Create**. You may need to give your own account a Key Vault role before you can complete the next steps.
4. In the key vault, go to **Certificates** and generate a new certificate:
   - Name: for example `tablSync`
   - Type of certificate authority: `Self-signed certificate`
   - Subject: `CN=tablSync`
   - Validity period: `12` months (the default)
   - Leave the other settings at their defaults.
5. In the key vault's **Access control (IAM)**, assign the **Key Vault Certificate User** role to the automation account's managed identity. This lets the runbook read the certificate to authenticate to Exchange Online.
6. Open the certificate, download it in **CER** format (public key only), and upload that file to the app registration under **Certificates & secrets** › **Certificates**. Without this step the application can't authenticate.

The certificate expires after 12 months. When you renew it, upload the new public key to the app registration as well.

## 6. Create a runtime environment

1. In the automation account, expand **Process Automation** and select **Runtime Environments**.
2. Create a custom **PowerShell 7.4** runtime environment and add these packages from the gallery:
   - `ExchangeOnlineManagement`
   - `Az` (normally included by default)

## 7. Create the runbook

1. In the automation account, go to **Process Automation** › **Runbooks** and create a new runbook:
   - Runbook: `Create new`
   - Name: your choice
   - Runbook type: `PowerShell`
   - Runtime environment: the one you have just created
   - Description: your choice
2. Paste in the script below. I developed it with AI assistance and have tested it in my own environment.
3. Edit the parameter block at the top to match your setup. Each placeholder in angle brackets explains what it needs.
4. Save and publish the runbook.
5. Start the runbook manually and check the output before scheduling it. Expect some debugging the first time.

The script deletes the watchlist and recreates it with the current block list. While it runs there is a short window where the watchlist is empty, so avoid relying on it in analytics rules that run at the same moment. If the block list comes back empty, the script stops without touching the watchlist.

```powershell
<#
.SYNOPSIS
    Syncs Tenant Allow/Block List (TABL) block entries to a Microsoft Sentinel watchlist.
.DESCRIPTION
    Authenticates to Azure with the automation account's managed identity and to
    Exchange Online with a Key Vault certificate. Includes retries with exponential
    back-off, CSV escaping, a guard against wiping the watchlist when no items are
    returned, and session clean-up.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApplicationId = "<application (client) ID of the app registration with the Exchange Online role>",

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = "<name of the key vault holding the certificate>",

    [Parameter(Mandatory = $false)]
    [string]$CertificateName = "<name of the certificate in the key vault>",

    [Parameter(Mandatory = $false)]
    [string]$OrganizationDomain = "<your tenant's initial domain, normally something.onmicrosoft.com>",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "<ID of the subscription that holds your Sentinel workspace>",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "<resource group that holds your Sentinel workspace>",

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName = "<name of your Sentinel Log Analytics workspace>",

    [Parameter(Mandatory = $false)]
    [string]$WatchlistAlias = "tablSync",

    [Parameter(Mandatory = $false)]
    [string]$SearchKey = "blockedItem"
)

# Enable verbose logging streams in Azure Automation Output
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Helper Function: Exponential Backoff Retry Logic
function Invoke-WithRetry {
    param(
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetry = 3,
        [int]$InitialDelaySec = 5,
        [string]$ActionName = "Operation"
    )
    $Attempt = 0
    while ($Attempt -lt $MaxRetry) {
        try {
            $Attempt++
            return &$ScriptBlock
        } catch {
            if ($Attempt -ge $MaxRetry) {
                Write-Error "[$ActionName] Failed after $MaxRetry attempts: $_"
                throw $_
            }
            $Delay = $InitialDelaySec * [Math]::Pow(2, ($Attempt - 1))
            Write-Warning "[$ActionName] Attempt $Attempt failed. Retrying in $Delay seconds... Error: $($_.Exception.Message)"
            Start-Sleep -Seconds $Delay
        }
    }
}

Write-Verbose "=================================================================="
Write-Verbose "STARTING: TABL to Sentinel Watchlist Sync Job"
Write-Verbose "Time (UTC): $((Get-Date).ToUniversalTime().ToString('o'))"
Write-Verbose "=================================================================="

# ----------------------------------------------------------------------
# 1. Module Loading & Azure Authentication
# ----------------------------------------------------------------------
Write-Verbose "`n[1/4] Loading modules and authenticating via Managed Identity..."
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.KeyVault -ErrorAction Stop
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
} catch {
    throw "Fatal error loading required PowerShell modules: $_"
}

try {
    $AzContext = Connect-AzAccount -Identity -ErrorAction Stop
    Write-Verbose "  [SUCCESS] Authenticated as Account ID: $($AzContext.Context.Account.Id)"
} catch {
    throw "[CRITICAL] Step 1 Managed Identity Authentication Failed: $_"
}

# ----------------------------------------------------------------------
# 2. Key Vault & Exchange Online Connection
# ----------------------------------------------------------------------
Write-Verbose "`n[2/4] Fetching Certificate [$CertificateName] from Key Vault [$KeyVaultName]..."
try {
    $CertSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $CertificateName -AsPlainText -ErrorAction Stop
    
    if ([string]::IsNullOrWhiteSpace($CertSecret)) {
        throw "Key Vault secret payload was null or empty."
    }
    
    $CertBytes = [System.Convert]::FromBase64String($CertSecret)
    $X509Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $CertBytes, 
        [string]::Empty, 
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    )
    Write-Verbose "  [SUCCESS] Certificate instantiated successfully."

    Write-Verbose "`n[2b/4] Connecting to Exchange Online PowerShell..."
    Invoke-WithRetry -ActionName "EXO Connection" -ScriptBlock {
        Connect-ExchangeOnline `
            -AppId $ApplicationId `
            -Certificate $X509Cert `
            -Organization $OrganizationDomain `
            -ShowBanner:$false `
            -ErrorAction Stop
    }
    Write-Verbose "  [SUCCESS] Connected to Exchange Online."
} catch {
    throw "[CRITICAL] Step 2 Authentication setup failed: $_"
}

# ----------------------------------------------------------------------
# 3. Fetch TABL Blocked Items
# ----------------------------------------------------------------------
Write-Verbose "`n[3/4] Pulling Tenant Allow/Block List (TABL) items..."
$TablItems = @()
$ListTypes = @("Url", "FileHash", "Sender")

try {
    foreach ($Type in $ListTypes) {
        Write-Verbose "  [DEBUG] Querying TABL items for Type: $Type..."
        $Results = Invoke-WithRetry -ActionName "Get-TABL-$Type" -ScriptBlock {
            Get-TenantAllowBlockListItems -ListType $Type -Block -ErrorAction Stop
        }

        $Count = if ($Results) { $Results.Count } else { 0 }
        Write-Verbose "  [DEBUG] Received $Count entry/entries for Type: $Type"

        foreach ($Item in $Results) {
            # Sanitize Notes & Values to ensure strict CSV compliance
            $CleanNotes = if ($Item.Notes) { 
                $Item.Notes -replace '[\r\n\t]', ' ' -replace '"', '""'
            } else { 
                "N/A" 
            }
            
            $CleanValue = if ($Item.Value) {
                $Item.Value -replace '"', '""'
            } else {
                continue
            }

            $ExpDate = if ($Item.ExpirationDate) { $Item.ExpirationDate.ToString("o") } else { "Never" }

            $TablItems += [PSCustomObject]@{
                blockedItem    = $CleanValue
                Type           = $Type
                Value          = $CleanValue
                ExpirationDate = $ExpDate
                Notes          = $CleanNotes
            }
        }
    }
} finally {
    # Guarantees session closure regardless of failure in fetch block
    Write-Verbose "  [DEBUG] Tearing down Exchange Online session..."
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}

Write-Verbose "  [SUCCESS] Retrieved $($TablItems.Count) total active blocked items from TABL."

# Zero-State Safety Guard: Prevents purging Sentinel Watchlist if EXO returns 0 items during an outage
if ($TablItems.Count -eq 0) {
    Write-Warning "No block records retrieved from TABL. Aborting Sentinel Watchlist update to prevent wiping active watchlist."
    return
}

# ----------------------------------------------------------------------
# 4. ARM REST API Payload Construction & Bulk Update
# ----------------------------------------------------------------------
Write-Verbose "`n[4/4] Preparing ARM REST API payload and headers..."

# Build RFC-4180 Compliant CSV Payload
$CsvLines = [System.Collections.Generic.List[string]]::new()
$CsvLines.Add("""$SearchKey"",""Type"",""Value"",""ExpirationDate"",""Notes""")

foreach ($Item in $TablItems) {
    $CsvLines.Add("""$($Item.blockedItem)"",""$($Item.Type)"",""$($Item.Value)"",""$($Item.ExpirationDate)"",""$($Item.Notes)""")
}
$RawCsvContent = $CsvLines -join "`r`n"
Write-Verbose "  [DEBUG] CSV Payload Built ($($CsvLines.Count) total lines including header)."

# Obtain ARM Authorization Token (Updated for Az 13+ compatibility)
try {
    Write-Verbose "  [DEBUG] Requesting ARM Access Token via Managed Identity..."
    $TokenObj = Get-AzAccessToken -ResourceUrl "https://management.azure.com" -AsSecureString -ErrorAction Stop
    
    if ($TokenObj.Token -is [System.Security.SecureString]) {
        $ArmToken = [System.Net.NetworkCredential]::new("", $TokenObj.Token).Password
    } else {
        $ArmToken = $TokenObj.Token
    }
    Write-Verbose "  [SUCCESS] Acquired Bearer token for https://management.azure.com."
} catch {
    throw "[CRITICAL] Failed to acquire ARM token via Managed Identity: $_"
}

$Headers = @{
    "Authorization" = "Bearer $ArmToken"
}

$ApiVersion   = "2023-02-01-preview"
$WatchlistUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/providers/Microsoft.SecurityInsights/watchlists/${WatchlistAlias}?api-version=$ApiVersion"

Write-Verbose "  [DEBUG] Target Watchlist URI: $WatchlistUri"

# Step 4a: Delete existing Watchlist container
Write-Verbose "`n  [DEBUG] API Call #1: Deleting existing Watchlist container [$WatchlistAlias]..."
try {
    Invoke-RestMethod `
        -Uri $WatchlistUri `
        -Method Delete `
        -Headers $Headers `
        -TimeoutSec 30 `
        -ErrorAction Stop | Out-Null

    Write-Verbose "  [DEBUG] Container purge request sent successfully."
    Write-Verbose "  [DEBUG] Pausing 5 seconds for ARM backend cleanup..."
    Start-Sleep -Seconds 5
} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
    if ($_.Exception.Response.StatusCode -ne [System.Net.HttpStatusCode]::NotFound) {
        Write-Warning "  [WARNING] Watchlist deletion returned unexpected HTTP status: $($_.Exception.Message)"
    } else {
        Write-Verbose "  [DEBUG] Watchlist container does not exist yet. Proceeding with creation..."
    }
} catch {
    Write-Warning "  [WARNING] Non-fatal error during Watchlist deletion: $_"
}

# Step 4b: Recreate Watchlist Container with Raw CSV
Write-Verbose "`n  [DEBUG] API Call #2: Recreating Watchlist container with raw CSV payload..."

$PayloadObject = @{
    properties = @{
        displayName         = $WatchlistAlias
        description         = "Synced TABL Block items from Exchange Online"
        provider            = "Microsoft Defender"
        source              = "Exchange Online TABL"
        sourceType          = "Local"
        itemsSearchKey      = $SearchKey
        contentType         = "text/csv"
        rawContent          = $RawCsvContent
        numberOfLinesToSkip = 0
    }
}

$JsonBody = $PayloadObject | ConvertTo-Json -Depth 5 -Compress
$Utf8BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)

try {
    $Response = Invoke-WithRetry -ActionName "Upload-Watchlist" -MaxRetry 3 -ScriptBlock {
        Invoke-RestMethod `
            -Uri $WatchlistUri `
            -Method Put `
            -Headers $Headers `
            -Body $Utf8BodyBytes `
            -ContentType "application/json; charset=utf-8" `
            -TimeoutSec 60 `
            -ErrorAction Stop
    }

    Write-Verbose "`n=================================================================="
    Write-Verbose "BULK SYNC COMPLETED SUCCESSFULLY!"
    Write-Verbose "Uploaded Items:  $($TablItems.Count)"
    Write-Verbose "Created Time:    $($Response.properties.created)"
    Write-Verbose "Resource ID:     $($Response.id)"
    Write-Verbose "=================================================================="

    # Output machine-readable JSON summary to output stream for Log Analytics
    $Summary = [PSCustomObject]@{
        Status         = "Success"
        ItemCount      = $TablItems.Count
        CreatedTime    = $Response.properties.created
        WatchlistAlias = $WatchlistAlias
        ResourceId     = $Response.id
    }
    
    $Summary | ConvertTo-Json -Compress | Write-Output

} catch {
    throw "[CRITICAL] Watchlist Upload Failed: $_"
}
```

## 8. Link the runbook to a schedule

1. Once the runbook works, open its **Overview** page and select **Link to schedule**.
2. Create a schedule that matches how often your block list changes. In my organisation changes happen sporadically through the day, so the watchlist is updated hourly.
3. Override any parameter defaults if needed, then save.
4. Check the job output after the first scheduled run to confirm the watchlist was updated.

## 9. Use the watchlist in advanced hunting

To list the watchlist:

```kql
_GetWatchlist('tablSync')
```

To find email from senders that are now on the block list, matching either the exact address or the domain:

```kql
// Blocked senders from the watchlist, lower-cased for matching
let WatchlistData = _GetWatchlist('tablSync')
    | where Type == "Sender"
    | project BlockedItem = tolower(tostring(blockedItem));
// Split into full email addresses and domain-only entries
let BlockedEmails = WatchlistData
    | where BlockedItem contains "@"
    | project BlockedItem;
let BlockedDomains = WatchlistData
    | where BlockedItem !contains "@"
    | project BlockedItem;
EmailEvents
| extend SenderMailFromAddressLower = tolower(SenderMailFromAddress),
         SenderFromAddressLower     = tolower(SenderFromAddress),
         SenderMailFromDomainLower  = tolower(SenderMailFromDomain),
         SenderFromDomainLower      = tolower(SenderFromDomain)
| where SenderMailFromAddressLower in (BlockedEmails)
    or SenderFromAddressLower in (BlockedEmails)
    or SenderMailFromDomainLower in (BlockedDomains)
    or SenderFromDomainLower in (BlockedDomains)
```

From here you can join the watchlist to other tables, for example `UrlClickEvents` for blocked URLs or `DeviceFileEvents` for blocked file hashes.
