---
layout: post
title: Detect ClickFix attack
description: A starting point for detecting ClickFix attacks against windows computers in the environment
date: 2026-09-08
categories:
  - ClickFix
  - investigations
tags:
  - KQL
  - Advanced hunting
---

This query is based on the query from [The One Chokepoint to Rule Them All: ](https://ddosier-disects.medium.com/the-one-chokepoint-to-rule-them-all-why-i-deleted-50-clickfix-detection-rules-and-replaced-them-7c532206d32d) Why I Deleted 50 ClickFix Detection Rules and Replaced Them With One. I had to do quite a bit of debugging for my environment and tailoring for my environment. 

If it runs in your environment, you can use this for a detection rule and have incidents automatically inserted into your [todo list](https://security.microsoft.com/incidents)

```kql
let ClipboardAccess = DeviceEvents
| where ActionType contains "GetClipboardData"
| where InitiatingProcessFileName in~
      ("powershell.exe","pwsh.exe","cmd.exe","wscript.exe",
       "cscript.exe","mshta.exe","wt.exe","RunDll32.exe")
| where InitiatingProcessCommandLine has_any
      ("Get-Clipboard","[System.Windows.Forms.Clipboard]",
       "clip","pbpaste")
| extend ClipTime=Timestamp,
      ClipInitProc=InitiatingProcessFileName,
      ClipCmdLine=InitiatingProcessCommandLine;
let ShellSpawn = DeviceProcessEvents
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
    | where ProcessCommandLine !contains "c:\\ProgramData\\scripts\\RemoveApps.ps1" // a file we appear to use here so excluding
    | project ShellSpawnTime=Timestamp, DeviceName, // there is no sessionId
      InitiatingProcessAccountName,
      FileName, ProcessCommandLine,
      InitiatingProcessFileName, IsSuspiciousCmdLine;
let NetworkEgress = DeviceNetworkEvents
    | where InitiatingProcessFileName in~
      ("powershell.exe","pwsh.exe","cmd.exe","mshta.exe",
       "curl.exe","wscript.exe","cscript.exe","certutil.exe",
       "bitsadmin.exe","msiexec.exe","RunDll32.exe")
    | where RemotePort in (80, 443, 8080, 8443, 4444, 4445, 1337)
    //Exclude known-safe Microsoft update / telemetry destinations
    | where RemoteUrl !has "microsoft.com"
        and RemoteUrl !has "windowsupdate.com"
        and RemoteUrl !has "adl.windows.com"
        and RemoteUrl !has "office365.com"
        and RemoteUrl !has "ocsp.digicert.com"
        and RemoteUrl !has "crl.globalsign.com"
        and RemoteUrl !has "api.anthropic.com"
        and RemoteUrl !has "updates.logitech.com"
        and RemoteUrl !has "aka.ms"
        and RemoteUrl !has "oscp2.globalsign.com"
        and RemoteUrl !contains "custom domains here"
    | project NetTime=Timestamp, DeviceName, // there is no sessionId
      NetInitProc=InitiatingProcessFileName,
      RemoteUrl, RemoteIP, RemotePort;
let ShellToNet = ShellSpawn
    | join kind=inner NetworkEgress
        on DeviceName //, there is no SessionId
    | where NetTime between (ShellSpawnTime .. (ShellSpawnTime + 180s)) // tune this line to how fast you think your users are
    | project ShellSpawnTime, NetTime, DeviceName, // there is no , SessionId,
      FileName, ProcessCommandLine, InitiatingProcessFileName,
      RemoteUrl, RemoteIP, RemotePort, IsSuspiciousCmdLine,
      InitiatingProcessAccountName
    | extend CorrelationPath = "ShellToNet";
let ClipToShell = ClipboardAccess
    | join kind=inner ShellSpawn
        on DeviceName // there is no , SessionId
    | where ShellSpawnTime between (ClipTime .. (ClipTime + 60s))
    | project ClipTime, ShellSpawnTime, DeviceName, // there is no, SessionId,
      FileName, ProcessCommandLine, InitiatingProcessFileName,
      ClipCmdLine, IsSuspiciousCmdLine,
      InitiatingProcessAccountName
    | extend CorrelationPath = "ClipboardToShell";
//Union and Score
union ShellToNet, ClipToShell
| extend ConfidenceScore = case(
    // CRITICAL: In-memory execution / encoded payloads
    ProcessCommandLine has_any (
        "IEX", "Invoke-Expression", "-enc", "-EncodedCommand",
        "DownloadString", "Get-Clipboard",
        "vbscript:", "javascript:"
    ), "CRITICAL",
    // HIGH: Remote download / living-off-land
    ProcessCommandLine has_any (
        "Invoke-WebRequest", "iwr", "curl", "wget",
        "DownloadFile", "certutil -urlcache",
        "bitsadmin /transfer", "msiexec /i http"
    ), "HIGH",
    // HIGH: Persistence / evasion indicators
    ProcessCommandLine has_any (
        "schtasks", "reg add", @"HKCU:\", "Bypass",
        "-WindowStyle Hidden", "-NonInteractive"
    ), "HIGH",
    // MEDIUM: Suspicious but not conclusive
    IsSuspiciousCmdLine == true, "MEDIUM",
    // LOW: Default fallback
    "LOW"
)
| where ConfidenceScore in ("CRITICAL","HIGH","MEDIUM")
//Dedup: one alert per device+session+cmdline combination ---
| summarize
    FirstSeen=min(ShellSpawnTime),
    AlertCount=count(),
    RemoteUrls=make_set(RemoteUrl, 10),
    RemoteIPs=make_set(RemoteIP, 10),
    CorrelationPaths=make_set(CorrelationPath)
    by DeviceName, FileName, // there is no sessionId
       ProcessCommandLine, InitiatingProcessFileName,
       ConfidenceScore, InitiatingProcessAccountName
| sort by ConfidenceScore asc, FirstSeen desc
//| distinct ProcessCommandLine
```