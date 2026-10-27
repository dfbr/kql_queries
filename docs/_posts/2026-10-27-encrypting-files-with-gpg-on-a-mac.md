---
title: Encrypting files with GPG on a Mac
created: 2026-10-27
layout: post
description: Encrypt and decrypt files from Terminal using GPG on macOS
date: 2026-10-27
categories:
  - guide
tags:
  - guide
  - GPG
  - encryption
  - Mac
---

_This guide assumes you've already [installed GPG tools]({% post_url 2026-09-14-gpg %}) on your mac and that you've [created and published]({% post_url docs/_posts/2026-09-15-create-and-publish-a-pgp-or-gpg-key %}) your keys._

## Encrypt text using GPG on a Mac

- Open your text editor of preference (an outlook message works well, as would TextEdit or VS Code)
- Write the message that you wish to encrypt
- Highlight the text
- Right click on the text and go to the `Services` menu
- Select the appropriate `OpenPGP: Encrypt Selection` option (actual text may differ depending on version)
![Highlight -> Services -> Encrypt](/assets/images/0fe72a3a1e1d45f6ad91c3a63340b01e.png)
- Select the recipients
	- You should _almost_ always add yourself as a recipient otherwise you'll never be able to read the message again
	- Select who to sign the message as
	- Click the encrypt button
![Select recipients and ](/assets/images/e4eaadcec9e4468bb663a4e2ecf3e0cd.png)

- Paste the entire resulting message into the communications method of your choice
	- Email
	- Teams
	- Chat
	- Printed paper

_Barring unforseen errors, no one who does not have the private key of one of the recipients will be able to read the message._
_Barring unforseen errors, it is impossible that anyone who doesn't have the private key of the signing keypair could have created this message._