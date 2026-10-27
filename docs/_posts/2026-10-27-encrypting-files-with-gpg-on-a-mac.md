---
title: Encrypting messages and files with GPG on a Mac
created: 2026-10-27
layout: post
description: Encrypt and decrypt text with the macOS Services menu, and files from Terminal, using GPG.
date: 2026-10-27
categories:
  - guide
tags:
  - guide
  - GPG
  - encryption
  - Mac
---

_This guide assumes you've already [installed the GPG tools]({% post_url 2026-09-14-gpg %}) on your Mac and [created and published]({% post_url 2026-09-15-create-and-publish-a-pgp-or-gpg-key %}) your key._

## Encrypt a message

1. Open any text editor (an Outlook message, TextEdit or VS Code all work) and write your message.
2. Select the text, right-click, go to **Services** and choose **OpenPGP: Encrypt Selection**. The exact wording may differ between versions.
   ![Highlight, then Services, then Encrypt](/assets/images/0fe72a3a1e1d45f6ad91c3a63340b01e.png)
3. Choose the recipients.
   - Almost always add yourself as a recipient, or you won't be able to read the message again.
   - Choose your own key to sign the message, so the recipient can confirm it came from you.
4. Select **Encrypt**.
   ![Selecting recipients and signing key](/assets/images/e4eaadcec9e4468bb663a4e2ecf3e0cd.png)
5. Copy the whole encrypted block, including the `BEGIN` and `END` lines, and send it however you like: email, Teams, chat or even on paper.

To read an encrypted message, select the whole block and use **Services** › **OpenPGP: Decrypt Selection**.

## Encrypt and decrypt files in Terminal

```sh
# Encrypt and sign a file for a recipient and yourself (creates report.pdf.gpg)
gpg --encrypt --sign --recipient them@example.com --recipient you@example.com report.pdf

# Decrypt it (also checks the signature)
gpg --output report.pdf --decrypt report.pdf.gpg
```

## What this protects

Only someone holding the private key of one of the recipients can read the message. If you signed it, a recipient who verifies the signature can be confident it came from the holder of your private key and wasn't changed on the way.
