---
title: "IRT Thursdays: a weekly habit that makes incident response stick"
layout: post
published: false # draft: review, then remove this line to publish
description: How we use Thursdays for informal, SME-led incident response training across the team, and ten topics to try if you want to do the same.
date: 2026-11-13
categories:
  - incident response
tags:
  - incident response
  - training
  - teamwork
  - leadership
---

Every Thursday, our incident response team (IRT) spends a short, informal session working through one practical question together. No slides, no scoring, no pass or fail. Just one real problem we might face during an incident, and the people best placed to answer it.

I started IRT Thursdays because incidents rarely fail on the big things. They stall on the small, practical questions nobody has asked in calm conditions: who can pull that log, who has access to that console, who signs off on the message to users. Formal exercises are valuable, but they are infrequent and heavy to organise. A weekly habit is light enough to keep going and regular enough to build real muscle memory.

The aim is to run it every week, but in reality some weeks get missed. Live incidents, leave and busy periods all get in the way. That's fine. The habit matters more than a perfect record, and we simply pick it up again the following Thursday.

## How it works

Each week starts with a single question, framed the way it would come up in a real incident. For example:

- "How do we know which user made this change?"
- "We need to draft a message to users and publish it. How do we do this, and who works on it?"

The question decides who leads. If it is about identity and audit logs, the identity team leads. If it is about user communications, the people who own our comms channels lead. The lead is the subject matter expert (SME) for that area, not me, and it rotates every week.

The lead's job is simple:

1. Walk through how we would actually answer the question today, live, in the real tools where possible.
2. Point out where it is slow, unclear or depends on one person.
3. Capture what we learned so it is findable next time.

Sessions are deliberately informal. Questions are welcome at any level, and "I don't know" is a perfectly good answer, because finding that out on a Thursday is far cheaper than finding it out at 2am during an incident.

## Coordinating it through Teams

All of the coordination happens in our IRT Teams channel. That keeps it visible, asynchronous and low effort, and it is the same channel we use when an incident is live, so people are used to looking there.

Each week I post the question in advance and tag the lead. The post invites everyone, not just the lead's team, to add thoughts, related questions or things that have caught them out before. Some of the best input comes from people outside the lead's area, who ask the obvious questions that experts have stopped noticing.

My role is to coordinate, not to answer. I set the question, make sure the right person is leading, keep the thread moving and make sure the outcome gets written down. The SME owns the content for their area. That balance matters: people engage more when it is their expertise on show, and the rest of the team learns from the person who actually does the work.

## What it has changed

**We work together better.** People now know who to call for what, and they have already worked through a problem with that person in a low-pressure setting. When an incident comes in, the first conversation is quicker because the relationships already exist.

**Our documentation has improved.** Every session produces something written down: a query, a runbook step, a contact, a decision about who owns what. Over time those notes have become a practical library built around the questions we actually get asked, rather than documentation written for an audit.

**We understand our strengths and weaknesses.** Some questions are answered in five minutes. Others expose a single point of failure, a missing permission, or a log we assumed we kept but don't. Both outcomes are useful. The strengths give the team confidence; the weaknesses become a prioritised list of improvements, found on our terms rather than an attacker's.

## Ten topics to try

If you want to start something similar, here are ten questions that work well. Each one has a natural lead and tends to surface something worth fixing.

1. **"A user's account looks compromised. How do we contain it in the next 15 minutes?"** Disable sign-in, revoke sessions and tokens, reset credentials, check MFA methods and inbox rules.
2. **"Which user or admin made this change, and when?"** Finding the right audit log, how far back it goes, and who has access to query it.
3. **"We need to tell users something now. How do we draft, approve and publish it?"** Channels, templates, who signs off, and how to reach people if email itself is affected.
4. **"A device is behaving suspiciously. How do we isolate it, and who decides?"** Isolation tooling, the authority to use it, and the impact on the user.
5. **"What evidence do we need to preserve before we fix anything?"** Logs, memory, disk images, retention periods, and chain of custody basics.
6. **"Is this a personal data breach, and do we need to report it?"** Working with the data protection officer, reporting deadlines, and what information they need from us.
7. **"A critical supplier tells us they have been breached. What now?"** Contracts and contacts, what access they hold, and how to assess our exposure.
8. **"Our primary tools are down or untrusted. How do we communicate and coordinate?"** Out-of-band contact lists, backup channels, and who keeps the incident log.
9. **"How do we find every system affected by this vulnerability or indicator?"** Asset inventory, vulnerability scan data, and hunting queries across the estate.
10. **"The incident is over. How do we run the lessons-learned review and make sure actions happen?"** Blameless review, owners and dates for actions, and how they are tracked to closure.

## Getting started

You don't need a budget or a formal programme. Pick one question, pick the person who knows the answer, post it in your team channel and give it half an hour. Write down what you learn. Then do it again next week with someone else leading.

The value is in the habit. One session will teach you something; a few months of them will change how your team works together when it matters.
