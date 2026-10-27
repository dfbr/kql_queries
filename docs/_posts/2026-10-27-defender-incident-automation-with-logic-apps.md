---
title: Automating Defender incident handling with Logic Apps
layout: post
published: false # draft outline: fill in, then remove this line to publish
description: How we use Azure Logic Apps to handle different types of Microsoft Defender incident automatically.
date: 2026-10-27
categories:
  - guide
tags:
  - Defender
  - Sentinel
  - Logic Apps
  - automation
---

<!--
DRAFT OUTLINE. Every section below needs your own detail before publishing.
Remove internal names, tenant details and anything that identifies your employer's environment.
-->

## Why automate incident handling

<!-- The problem: incident volume, repetitive triage steps, time to first response. -->

## How it's set up

We run a set of Azure Logic Apps, each handling a different type of Microsoft Defender incident. Each Logic App has its own system-assigned managed identity, and most of them post a notification to Microsoft Teams.

<!--
- How incidents reach each Logic App (automation rule, trigger type)
- Why one Logic App per incident type rather than one large playbook
- What permissions each managed identity needs, and how you keep them least-privilege
-->

## Example: <!-- pick one incident type -->

<!--
- Trigger
- Enrichment or checks it performs
- Actions it takes automatically
- The Teams message it sends, and who receives it
- A redacted screenshot of the designer view
-->

## Lessons learned

<!--
- What went wrong or surprised you
- How you test changes safely
- How you monitor failed runs
- What you'd do differently
-->
