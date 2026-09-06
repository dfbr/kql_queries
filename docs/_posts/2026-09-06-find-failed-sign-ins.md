---
layout: post
title: Find failed sign-in attempts by user
description: A starting point for reviewing failed Microsoft Entra sign-ins over a recent time window.
date: 2026-09-06
categories:
  - identity
  - investigations
tags:
  - sign-in logs
  - Microsoft Entra ID
---

This query summarizes failed sign-in attempts by user and application. Adjust the time range and result filters for the investigation at hand.

## Query

```kusto
let lookback = 24h;
SigninLogs
| where TimeGenerated >= ago(lookback)
| where ResultType != 0
| summarize
    FailedAttempts = count(),
    LastAttempt = max(TimeGenerated),
    Applications = make_set(AppDisplayName, 10)
    by UserPrincipalName, ResultDescription
| order by FailedAttempts desc
```

## Notes

- `ResultType != 0` keeps unsuccessful sign-ins. Confirm the result semantics for the log source you are using.
- `make_set()` keeps the application context compact when a user has tried several applications.
- Add `IPAddress`, `Location`, or `ConditionalAccessStatus` to the grouping when the investigation needs that detail.
