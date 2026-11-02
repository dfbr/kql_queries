---
title: Detecting new local accounts on Windows clients with Defender
layout: post
description: Detecting new local accounts on Windows clients with Defender
date: 2026-11-02
categories:
  - guide
tags:
  - Defender
  - Logic Apps
  - automation
  - Windows
---

## Local accounts

We run a Windows domain for our environment. As such, we _shouldn't_ have local accounts on our Windows machines (Mac and Linux are another topic for another day!). Sometimes though, we see them being created. But why? Local accounts are a classic persistence tactic (MITRE ATT&CK T1136.001)

Without proper monitoring and alerting to find new accounts, we can't really know. So... Defender advanced hunting to the rescue! The `DeviceEvents` table logs just these events so we can query the table and have a custom detection rule whenever a new local account is created. Here is my query (with a few organisation specific parts removed):

```kql
DeviceEvents
| where ActionType == "UserAccountCreated"
| where AccountDomain =~ DeviceName
    or AccountDomain =~ tostring(split(DeviceName, ".")[0])
// some accounts we're not interested in. Include them in this list below
| where AccountName !in ("lapsadmin")
| where AccountName !startswith "shpctac" // to avoid shared pc accounts
| project Timestamp, DeviceId, ReportId, DeviceName, AccountName, AccountSid,
          InitiatingProcessAccountName, InitiatingProcessFileName,
          InitiatingProcessCommandLine
```

With this, and the custom detection rule running in near real time, we get to know as soon as a new account is created and take action - experience says people are more open to questions (and to knowing the answer) if you can contact them as soon as possible after something has happened.

Bottom line, most of the accounts are to do with AI agents (semi-tollerated in our environment) and can be added to the _OK_ list. More on this in a future post as time allows.

More accounts are for [laps](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview) so totally understandable. 

Then there is the `shpctac<string>` set of accounts. These are to do with shared PC features and also OK in our environment.

Of course, this allows an attacker to get around this detection with an account called `lapsadmin` or `shpctac<anythingTheAttackerWants>`. We're still seeing more than we would have done before though.

Other entries need investigating so get funnelled into an incident for analyst review. Manual work but just like a scientist getting to know their data, an analyst learning more about their environment is only a good thing.