---
title: Detecting new local accounts on Windows clients with Defender
layout: post
description: Detecting new local accounts on Windows clients with Defender
date: 2026-11-01
categories:
  - guide
tags:
  - Defender
  - Logic Apps
  - automation
  - Windows
---

## Local accounts


```kql
DeviceEvents
| where ActionType == "UserAccountCreated"
| where AccountDomain =~ DeviceName
    or AccountDomain =~ tostring(split(DeviceName, ".")[0])
// some accounts we're not interested in. Include them in this list below
| where AccountName !in (""lapsadmin")
| where AccountName !startswith "shpctac" // to avoid shared pc accounts
| project TimestampEntraIdSignInEvents , DeviceId, ReportId, DeviceName, AccountName, AccountSid,
          InitiatingProcessAccountName, InitiatingProcessFileName,
          InitiatingProcessCommandLine
```