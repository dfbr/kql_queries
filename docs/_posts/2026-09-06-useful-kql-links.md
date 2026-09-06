---
layout: post
title: Useful links
description: A practical starting list of documentation, learning resources, and tools for Information Security related work.
date: 2026-09-06
categories:
  - resources
tags:
  - reference
---

A short list of references I return to when writing, reviewing, or troubleshooting Kusto queries.

## KQL

- [Kusto Query Language overview](https://learn.microsoft.com/kusto/query/) — The main Microsoft Learn reference for KQL syntax, operators, functions, and language concepts.
- [KQL quick reference](https://learn.microsoft.com/kusto/query/kql-quick-reference) — A compact syntax reference for common query patterns.
- [Kusto Query Language reference](https://learn.microsoft.com/kusto/query/kql-reference) — Detailed language reference material for operators, statements, and expressions.
- [Kusto Explorer](https://dataexplorer.azure.com/) — A browser-based interface for exploring data with KQL when your environment and permissions allow access.

## Query patterns

- [Common KQL functions](https://learn.microsoft.com/kusto/query/scalar-functions) — Reference for scalar functions used to transform, parse, and inspect values.
- [Aggregation functions](https://learn.microsoft.com/kusto/query/aggregation-functions) — Functions for summarizing records with `summarize`.
- [String functions](https://learn.microsoft.com/kusto/query/scalar-functions#string-functions) — Useful when filtering, extracting, or normalizing text fields.
- [Time series analysis](https://learn.microsoft.com/kusto/query/time-series) — Patterns for analyzing trends, baselines, and anomalies over time.

## Azure Monitor and security

- [Azure Monitor Logs overview](https://learn.microsoft.com/azure/azure-monitor/logs/log-query-overview) — How Log Analytics workspaces and KQL fit together in Azure Monitor.
- [Microsoft Sentinel hunting](https://learn.microsoft.com/azure/sentinel/hunting) — Guidance for using KQL to investigate threats and develop hunting queries.
- [Microsoft Entra sign-in logs](https://learn.microsoft.com/entra/identity/monitoring-health/concept-sign-ins) — Field and behavior reference for sign-in data used in identity investigations.
- [Azure Resource Graph query samples](https://learn.microsoft.com/azure/governance/resource-graph/samples/samples-by-category) — Query examples for inventorying and analyzing Azure resources.

## Open Search

- [OpenSearch documentation](https://docs.opensearch.org/latest/) — The main reference for OpenSearch, Dashboards, APIs, and related components.
- [OpenSearch Query DSL](https://docs.opensearch.org/latest/query-dsl/) — Query syntax and examples for searching and filtering indexed data.
- [OpenSearch security plugin](https://docs.opensearch.org/latest/security/) — Documentation for authentication, authorization, encryption, and audit logging.

## Defender

- [Microsoft Defender XDR documentation](https://learn.microsoft.com/defender-xdr/) — Product documentation for Microsoft Defender XDR and its connected security experiences.
- [Advanced hunting overview](https://learn.microsoft.com/defender-xdr/advanced-hunting-overview) — Introduction to investigating security data with Advanced Hunting and KQL.
- [Advanced hunting query language](https://learn.microsoft.com/defender-xdr/advanced-hunting-query-language) — KQL guidance specific to Microsoft Defender data and hunting workflows.

## Powershell

- [PowerShell documentation](https://learn.microsoft.com/powershell/) — Official reference, tutorials, and administration guidance for PowerShell.
- [PowerShell scripting](https://learn.microsoft.com/powershell/scripting/overview) — Core concepts for writing, testing, and maintaining PowerShell scripts.
- [PowerShell Gallery](https://www.powershellgallery.com/) — Discover and review community modules and scripts.

## CCNA

- [Cisco CCNA certification](https://www.cisco.com/site/us/en/learn/training-certifications/certifications/associate/ccna/index.html) — Current certification overview, exam information, and learning paths.
- [CCNA exam topics](https://learningnetwork.cisco.com/s/ccna-exam-topics) — The Cisco exam-topics outline for planning study coverage.
- [Cisco Packet Tracer](https://www.netacad.com/courses/packet-tracer) — Network simulation tool for practicing topology, configuration, and troubleshooting concepts.

## AWS security

- [AWS security documentation](https://docs.aws.amazon.com/security/) — Central index for AWS security, identity, compliance, and governance documentation.
- [AWS Identity and Access Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) — Guidance for identities, permissions, policies, and access controls.
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) — Design principles and best practices for securing AWS workloads.
- [AWS Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html) — Centralized view of security findings and security posture checks across AWS accounts.

## Community and examples

- [Microsoft Security community KQL queries](https://github.com/Azure/Azure-Sentinel/tree/master/Hunting%20Queries) — Community-maintained Microsoft Sentinel hunting query examples.
- [Kusto Detective Agency](https://detective.kusto.dev/) — Interactive challenges for practicing KQL against investigative scenarios.

## Keeping this list useful

Prefer links to durable documentation, and add a sentence explaining why a resource is useful. When a link becomes specific to a tool, workspace, tenant, or internal process, move it to a separate private reference instead of publishing it here.
