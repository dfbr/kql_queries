---
layout: post
title: Detect ClickFix attacks
description: A starting-point advanced hunting query for detecting ClickFix attacks against Windows devices.
date: 2026-09-08
categories:
  - ClickFix
  - investigations
tags:
  - KQL
  - Advanced hunting
---

## What ClickFix is

__ClickFix__ is a social-engineering technique that tricks someone into running a command on their own computer. A web page shows a fake CAPTCHA or error message and tells the visitor to paste and run a command, usually through the Run dialog or a terminal. Because the user starts the process themselves, the activity looks different from a conventional malware download and can slip past detections built for that.

## Why one correlated rule beats many

ClickFix lures change constantly: new fake CAPTCHAs, new wording, new payload hosts and new obfuscation in the pasted command. Rules written for each variant multiply quickly, need constant upkeep and still miss the next variant.

What doesn't change is the chain of behaviour the attack depends on. The user copies something, a shell starts from an unusual parent such as the Run dialog, and that shell reaches out to the internet. Detecting that chain catches variants you haven't seen yet, gives you one rule to tune instead of dozens, and produces fewer, better-explained alerts because each hit shows the whole sequence.

## The query

This query is adapted from [The One Chokepoint to Rule Them All: Why I Deleted 50 ClickFix Detection Rules and Replaced Them With One](https://ddosier-disects.medium.com/the-one-chokepoint-to-rule-them-all-why-i-deleted-50-clickfix-detection-rules-and-replaced-them-7c532206d32d). I had to debug and tailor it for my environment, and you will probably need to do the same.

It looks for two patterns:

- **Clipboard to shell**: a script host reads the clipboard and a shell starts within 60 seconds.
- **Shell to network**: a shell starts from a typical ClickFix parent (such as `explorer.exe` from the Run dialog) and a script host makes an outbound connection within 180 seconds.

Each hit is scored by what the command line contains, and only medium-confidence and above are returned.

```kql
let Lookback = 1d; // widen for hunting, keep short for a detection rule
let ClipboardAccess = DeviceEvents
    | where Timestamp > ago(Lookback)
    | where ActionType contains "GetClipboardData"
    | where InitiatingProcessFileName in~
        ("powershell.exe","pwsh.exe","cmd.exe","wscript.exe",
         "cscript.exe","mshta.exe","wt.exe","RunDll32.exe")
    | where InitiatingProcessCommandLine has_any
        ("Get-Clipboard","[System.Windows.Forms.Clipboard]","clip")
    | project ClipTime = Timestamp, DeviceId,
        ClipInitProc = InitiatingProcessFileName,
        ClipCmdLine = InitiatingProcessCommandLine;
let ShellSpawn = DeviceProcessEvents
    | where Timestamp > ago(Lookback)
    | where FileName in~
        ("powershell.exe","pwsh.exe","cmd.exe","mshta.exe",
         "wscript.exe","cscript.exe","wt.exe","RunDll32.exe",
         "msiexec.exe","fodhelper.exe","schtasks.exe")
    | where InitiatingProcessFileName in~
        ("explorer.exe","SearchHost.exe","wt.exe",
         "RunDll32.exe","msiexec.exe","WerFault.exe",
         "DllHost.exe","fodhelper.exe","winlogon.exe",
         "userinit.exe","cmd.exe")
    // Exclude SYSTEM-context noise
    | where InitiatingProcessAccountName !in~ ("SYSTEM","LOCAL SERVICE","NETWORK SERVICE")
    // Key ClickFix payload indicators
    | extend IsSuspiciousCmdLine = ProcessCommandLine has_any (
        "IEX","Invoke-Expression","-enc","-EncodedCommand","-e ",
        "Get-Clipboard","DownloadString","DownloadFile",
        "Net.WebClient","Invoke-WebRequest","iwr","curl",
        "Start-Process","Hidden","Bypass","HKCU:\\","reg add",
        "schtasks","certutil","bitsadmin","mshta","vbscript:")
    | project ShellSpawnTime = Timestamp, DeviceId, DeviceName, ReportId,
        InitiatingProcessAccountName,
        FileName, ProcessCommandLine,
        InitiatingProcessFileName, IsSuspiciousCmdLine;
let NetworkEgress = DeviceNetworkEvents
    | where Timestamp > ago(Lookback)
    | where InitiatingProcessFileName in~
        ("powershell.exe","pwsh.exe","cmd.exe","mshta.exe",
         "curl.exe","wscript.exe","cscript.exe","certutil.exe",
         "bitsadmin.exe","msiexec.exe","RunDll32.exe")
    | where RemotePort in (80, 443, 8080, 8443, 4444, 4445, 1337)
    // Exclude known-safe Microsoft update and certificate destinations
    | where RemoteUrl !has "microsoft.com"
        and RemoteUrl !has "windowsupdate.com"
        and RemoteUrl !has "adl.windows.com"
        and RemoteUrl !has "office365.com"
        and RemoteUrl !has "ocsp.digicert.com"
        and RemoteUrl !has "crl.globalsign.com"
        and RemoteUrl !has "aka.ms"
        and RemoteUrl !has "ocsp2.globalsign.com"
        // Add your own organisation's trusted domains here, for example:
        // and RemoteUrl !has "example.com"
    | project NetTime = Timestamp, DeviceId,
        NetInitProc = InitiatingProcessFileName,
        RemoteUrl, RemoteIP, RemotePort;
let ShellToNet = ShellSpawn
    | join kind=inner NetworkEgress on DeviceId
    | where NetTime between (ShellSpawnTime .. (ShellSpawnTime + 180s)) // tune to how quickly your users act
    | project ShellSpawnTime, NetTime, DeviceId, DeviceName, ReportId,
        FileName, ProcessCommandLine, InitiatingProcessFileName,
        RemoteUrl, RemoteIP, RemotePort, IsSuspiciousCmdLine,
        InitiatingProcessAccountName
    | extend CorrelationPath = "ShellToNet";
let ClipToShell = ClipboardAccess
    | join kind=inner ShellSpawn on DeviceId // no session ID is available to tighten this
    | where ShellSpawnTime between (ClipTime .. (ClipTime + 60s))
    | project ClipTime, ShellSpawnTime, DeviceId, DeviceName, ReportId,
        FileName, ProcessCommandLine, InitiatingProcessFileName,
        ClipCmdLine, IsSuspiciousCmdLine,
        InitiatingProcessAccountName
    | extend CorrelationPath = "ClipboardToShell";
// Combine both patterns and score them
union ShellToNet, ClipToShell
| extend ConfidenceScore = case(
    // CRITICAL: in-memory execution or encoded payloads
    ProcessCommandLine has_any (
        "IEX", "Invoke-Expression", "-enc", "-EncodedCommand",
        "DownloadString", "Get-Clipboard",
        "vbscript:", "javascript:"
    ), "CRITICAL",
    // HIGH: remote download or living-off-the-land binaries
    ProcessCommandLine has_any (
        "Invoke-WebRequest", "iwr", "curl", "wget",
        "DownloadFile", "certutil -urlcache",
        "bitsadmin /transfer", "msiexec /i http"
    ), "HIGH",
    // HIGH: persistence or evasion indicators
    ProcessCommandLine has_any (
        "schtasks", "reg add", @"HKCU:\", "Bypass",
        "-WindowStyle Hidden", "-NonInteractive"
    ), "HIGH",
    // MEDIUM: suspicious but not conclusive
    IsSuspiciousCmdLine == true, "MEDIUM",
    // LOW: default
    "LOW"
)
| where ConfidenceScore in ("CRITICAL","HIGH","MEDIUM")
// One result per device, command line and score
| summarize
    arg_min(ShellSpawnTime, ReportId),
    AlertCount = count(),
    RemoteUrls = make_set(RemoteUrl, 10),
    RemoteIPs = make_set(RemoteIP, 10),
    CorrelationPaths = make_set(CorrelationPath)
    by DeviceId, DeviceName, FileName,
       ProcessCommandLine, InitiatingProcessFileName,
       ConfidenceScore, InitiatingProcessAccountName
| extend Timestamp = ShellSpawnTime // Timestamp, DeviceId and ReportId are required for a custom detection rule
| project-rename FirstSeen = ShellSpawnTime
| sort by ConfidenceScore asc, FirstSeen desc // alphabetical order happens to put CRITICAL first
```

## Using it as a detection rule

The query returns the `Timestamp`, `DeviceId` and `ReportId` columns that a custom detection rule needs. Once it runs cleanly and the false-positive rate is acceptable in your environment, you can save it as a [custom detection rule](https://learn.microsoft.com/en-us/defender-xdr/custom-detection-rules) so that matches raise incidents automatically. Set `Lookback` to match the rule's frequency.

## Tuning notes

- The shell-to-network pattern correlates on device and time only, so any script host traffic within the window counts. If it is too noisy, require the network connection to come from the spawned process itself.
- Add your organisation's own trusted domains to the `RemoteUrl` exclusions.
- Adjust the time windows to how quickly your users act.
