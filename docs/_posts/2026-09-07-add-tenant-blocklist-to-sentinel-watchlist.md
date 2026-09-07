---
title: Add tenant allow/block list as a watchlist in Microsoft Sentinel
updated: 2026-09-07 09:56:15Z
created: 2026-09-07 07:53:15Z
layout: post
description: A guide (but not verbatim) to adding the tenant allow/block list to sentinel as a watchlist
date: 2026-09-06
categories:
  - guide
tags:
  - guide sentinel watchlist "tenant allow block list"

---

# Add tenant allow/block list as a watchlist in Microsoft Sentinel
There is no native link between the tenant allow/block list and sentinel. By adding the block list (tabl) as a watchlist, you can integrate the entries to your advanced hunting queries allowing you to exclude results where there is a block entry. _I don't use allow lists here but you could use these instructions as a basis and extend to include the allow list as well._

To setup the watchlist you need to:

1. Create a template watchlist
2. Create an enterprise application
3. Assign the application a role in ExchangeOnline
4. Create an automation account
5. Create a key vault for the automation account
6. Create a runtime in the automation account
7. Create a runbook in the automation account
8. Link the runbook to a schedule
9. Use the watchlist in advanced hunting


## Details

#### Create a template watchlist
1. Copy the following code and save it to `tempfile.csv`
   ```csv
   blockedItem,Type,Value,ExpirationDate,Notes
   dummyEntry,dummyEntry,dummyEntry,dummyEntry,dummyEntry
   ```
2. In the [Microsoft security portal](https://security.microsoft.com) expand `Sentinel`, then `Configuration` and select `Watchlist`
3. Create a new watchlist:
	- Name `tablSync`
	- Description `<whatever you want>`
	- Alias `tablSync`
4. In the `Source` section:
	- Source type `Local file`
	- Filetype `CSV file with a header`
	- Number of lines before row with headings `0`
	- Upload your `tempfile.csv` that you created in step 1
	- Searchkey `blockedItem`
5. `Review + Create` then `Create`

### Create an enterprise application
1. Having elevated your Entra account to the correct role, go to App Registrations and create a new registration
   ![ba1388cdf1bf1ac98c67281a2f485aeb.png](../_resources/ba1388cdf1bf1ac98c67281a2f485aeb.png)
1. Enter the name for your app and choose single tenant only.
2. Click Register
3. Go to "Enterprise Applications" and select the application you have just created.
4. Go to permissions and add the permission `Office 365 Exchange Online` `Exhange.ManaeAsApp`
5. Grant admin consent for this permission

### Assign the application the required privileges in ExchangeOnline
1. In Exchange Online, add the role `View-Only Configuration` to the application that you've just created.

### Create the automation account
1. In Azure, go to `Automation Accounts` and create a new account
2. Enter relevant details for the `Subscription`, `Resource Group`, `Automation account name` and `Region`
3. Click `Review + Create` then `Create`
4. Go to the resource and select `Access control (IAM)`. Add the role `Microsoft Sentinel Automation Contributor` to the automation account. This allows the automation account to use the sentinel watchlist to add and remove entries.

#### Create a key vault for the automation account
1. In Azure, go to `Key vaults` and create a new key vault
2. Fill in the relevant details for the `Subscription`, `Resource group` etc. The subscription and resource group should be the same as for the automation account that you created previously.
3. Pricing tier should be standard.
4. `Review + create`, then `Create`
5. You may need to change/elevate your privileges on the new keyvault in order to complete the next steps.
6. Once created, go to the resource and create a new certificate:
	1. The certificate name should be something like `tabl sync`
	2. `Self signed` is perfectly fine for this purpose
	3. The Subject can be `CN=tablSync`
	4. You don't need to add any dns names
	5. Validity period of `12` months (the default) is OK for our purposes - you'll need to regenerate and replace it every 12 months
	6. Keep the rest of the settings as default and create the certificate
7. Go to `Access control (IAM)` for the key vault.
	1. Add the role `Key Vault Certificate User` for the automation account that you previously created (this allows the automation account to use the certificate for authentication later)

#### Create a runtime in the automation account
1. Go back to the automation account that you created earlier
2. Expand `Process Automation` and select `Runtime Environments`
3. Create a custom `powershell 7.4` runtime environment, from the gallery, add the following packages:
	- `ExhangeOnlineManagement`
	- `Az` (should be there by default)
	- `Azure CLI` (should be there by default)
  
#### Create a runbook in the automation account
1. Once the runtime is created, go to the section `Runbooks` in the `Process Automation` section of the automation account
5. Create a new runbook:
	- Runbook `Create new`
	- Name `<Your chosen name>`
	- Runbook type `Powershell`
	- Runtime Environment: select the environment you've just created
	- Description `<As you wish>`
6. Once the runbook is created, you are ready to enter the code for the script it will run. Here is the vibecoded script that I am using:
```
<Enter code here, redact and explain what must be edited>
<#
.SYNOPSIS
    Automated high-speed sync for Tenant Allow/Block List (TABL) items to 
    Microsoft Sentinel Watchlist using Key Vault Certificate Auth and Managed Identity.
.DESCRIPTION
    Production-grade runbook featuring robust error handling, exponential retries, 
    CSV escaping, zero-item deletion guards, Az 13+ token compatibility, and proper session teardown.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApplicationId = "<the applicationID of the enterprise application that has the exchangeOnline role>",

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = "<the name of the keyvault with the generated certificate>",

    [Parameter(Mandatory = $false)]
    [string]$CertificateName = "<the name of the certificate in the keyvault>",

    [Parameter(Mandatory = $false)]
    [string]$OrganizationDomain = "<your tenant's organisation name, normally something.onmicrosoft.com>",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "<the subscription ID for the subscription you're using>",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "<the resource group name for the resource group that your watchlist table is held in>",

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName = "<the workspace name that your sentinel logs use?",

    [Parameter(Mandatory = $false)]
    [string]$WatchlistAlias = "<your watchlist alias, probably tablSync>",

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
        displayName         = "Tenant Allow Block List"
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
7. Edit the parameter block (first section of the code) to inclue your specific values for your setup
8. Save and publish the code.

__NB: you will probably need to do some testing and debugging now, you can do this through manually starting the runbook and reviewing the output. GOOD LUCK!__

#### Link the runbook to a schedule
1. Assuming you managed to get the code working, you'll now want to link the runbook to a schedule. This can be a schedule of your choice depending on how often you update the tenant allow/block list. In my organisation, updates are sporadic throughout the day so the watchlist is updated once an hour. YMMV.
2. In the `Overview` section of the runbook, select `Link to Schedule`
3. Create a schedule to suit your use case, customise any of the default parameters if you need to (the defaults are taken from the code above) and apply it to the runbook
4. Watch the logs to see your successful updates to the watchlist

#### Use the watchlist in advanced hunting
1. The simplest use case is to just list the watchlist in advanced hunting. You should be able to do this with:
   ```kql
	 _GetWatchlist('<your watchlist alias>')
   ```
2. If you then want to do more interesting things, you could, for example, look for all emails where the sender is on the watchlist with something like:
   ```kql
	 _GetWatchlist('tenantAllowBlockList')
	| where Type == "Sender"
	// Step 1: Extract and categorize blocked items from your watchlist
	let WatchlistData = _GetWatchlist('tenantAllowBlockList')
	    | where Type == "Sender"
	    | project BlockedItem = tolower(tostring(blockedItem));
	// Split items into specific email addresses vs domain-only entries
	let BlockedEmails = WatchlistData 
	    | where BlockedItem contains "@" 
	    | project BlockedItem;
	let BlockedDomains = WatchlistData 
	    | where BlockedItem !contains "@" 
	    | project BlockedItem;
	// Step 2: Query Email events and filter by exact email OR domain match
	EmailEvents
	| extend SenderMailFromAddressLower = tolower(SenderMailFromAddress),
	         SenderFromAddressLower     = tolower(SenderFromAddress),
	         SenderMailFromDomainLower  = tolower(SenderMailFromDomain),
	         SenderFromDomainLower      = tolower(SenderFromDomain)
	| where 
	    // Match 1: Exact sender email matches the watchlist
	    SenderMailFromAddressLower in (BlockedEmails) 
	    or SenderFromAddressLower in (BlockedEmails)
	    // Match 2: Sender domain matches a domain entry in the watchlist
	    or SenderMailFromDomainLower in (BlockedDomains) 
	    or SenderFromDomainLower in (BlockedDomains)
   ```
   3. Now it's your turn to be creative with how you use it.