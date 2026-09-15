---
title: Create and publish a PGP/GPG key
updated: 2026-09-15
created: 2026-09-15
layout: post
description: A guide to creating and publishing a GPG/PGP key pair
date: 2026-09-15
categories:
  - guide
tags:
  - guide
  - PGP
  - GPG
  - encryption
  - key
  - keys

---

## Create and publish a key using the gui
- Open `GPG Keychain.app`
	- ![15f625e95c683ee4455138e7bd01a096.png](/assets/images/15f625e95c683ee4455138e7bd01a096.png)
- Select "New" in GPG Keychain
![Screenshot 2026-09-11 at 11.56.19.png](/assets/images/Screenshot%202026-09-11%20at%2011.56.19.png)
-Configure the settings
	- A name that will help you recognise the key
	- The email address that you want to be associated with this key (this will normally be your primary email address)
	- The expiry date (set this short for a test key, for a standard key 2 years is a good value to choose)
	- Set a good password - think of this as protecting your identity!
	- ![512b50043f4d413aedf35ead3ff99e41.png](/assets/images/512b50043f4d413aedf35ead3ff99e41.png)

- Publish the key to the key server (`hkps://keys.openpgp.org` should be set by default but you may need to configure it)
	- ![0fec2026e118dd91367173524677e385.png](/assets/images/0fec2026e118dd91367173524677e385.png)
- Receive an email from `keyserver@keys.openpgp.org` with a link to verify that you control the email address (and want to share the key)
		- Click on the link and follow further instructions if necessary

## Create and publish a key using the command line

The same can be achieved through the command line with the following recipe

```
# first create the signing key
gpg --quick-generate-key "Name your_email@example.com" ed25519 cert,sign 1d

# then find the key fingerprint
gpg --list-secret-keys --keyid-format LONG

# find the key fingerprint of the key you've just added and then add an encryption key
gpg --quick-add-key <YOUR FINGERPRINT> default encrypt 1d

```

In the above examples, the `1d` refers to the expiry date of the key and it sets the expiry date to 1 day in the future. you can use:
- `d` for days,
- `m` for months,
- `y` for years
- or ommit the expiry date and go with the default expiry period

## Lookup and import another key
- Lookup a key on the server
	![ffddf408c37739e2c7df4f8f7b065a3d.png](/assets/images/ffddf408c37739e2c7df4f8f7b065a3d.png)

- Verfiy with the person that this is the correct key
	- ![20a93f5a4f20628caaba6b11a357baa2.png](/assets/images/20a93f5a4f20628caaba6b11a357baa2.png)
	- If the fingerprints (the long hex value) match, then you can import the key
- Set the trust level of the key
	- Go to the details of the key
	- ![8c089d0e13ee385fb35e920ec349eb63.png](/assets/images/8c089d0e13ee385fb35e920ec349eb63.png)
	- Set the `Ownertrust` field to the appropriate value (probably `Full`)
		- ![63fad7d58855b4d4c49a78005d789a39.png](/assets/images/63fad7d58855b4d4c49a78005d789a39.png)

Your key is now created and published so that anyone can find it based on your email address.