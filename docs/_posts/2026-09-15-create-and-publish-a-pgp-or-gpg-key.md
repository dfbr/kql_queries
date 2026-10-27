---
title: Create and publish a PGP/GPG key
updated: 2026-10-27
created: 2026-09-15
layout: post
description: How to create a GPG key pair, publish it, back it up, and import and verify other people's keys.
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

This guide uses GPG Keychain on a Mac, with command-line equivalents at the end. See [which GPG applications to use]({% post_url 2026-09-14-gpg %}) for other platforms.

## Create and publish a key in GPG Keychain

1. Open **GPG Keychain**.
   ![GPG Keychain](/assets/images/15f625e95c683ee4455138e7bd01a096.png)
2. Select **New**.
   ![Creating a new key](/assets/images/Screenshot%202026-09-11%20at%2011.56.19.png)
3. Configure the key:
   - **Name**: a name that will help you and others recognise the key
   - **Email**: the address you want associated with the key, normally your primary address
   - **Expiry date**: two years is a sensible default for a real key; use a short expiry for a test key
   - **Passphrase**: use a strong one. It protects your identity.
   ![Key settings](/assets/images/512b50043f4d413aedf35ead3ff99e41.png)
4. Publish the key to the key server. `hkps://keys.openpgp.org` should be set by default, but you may need to configure it.
   ![Publishing the key](/assets/images/0fec2026e118dd91367173524677e385.png)
5. You'll receive an email from `keyserver@keys.openpgp.org` asking you to confirm that you control the address and want it published. Follow the link.

Once verified, anyone can find your key by searching for your email address.

## Back up your key and keep a revocation certificate

If you lose your private key you can't decrypt anything sent to you, and if it's stolen someone else can read your messages and sign as you. Before relying on the key:

- Export a backup of the private key and store it offline, for example on an encrypted USB drive.
- Keep a revocation certificate somewhere safe. GPG creates one automatically in `~/.gnupg/openpgp-revocs.d/`. If the key is ever lost or compromised, publishing it tells everyone to stop using the key.

## Import and verify someone else's key

1. Look up the person's key on the key server.
   ![Looking up a key](/assets/images/ffddf408c37739e2c7df4f8f7b065a3d.png)
2. Before importing, confirm with the person, by phone, in person or another channel you trust, that the fingerprint (the long hexadecimal value) matches their key.
   ![Confirming the key](/assets/images/20a93f5a4f20628caaba6b11a357baa2.png)
3. Import the key.
4. Sign the key to record that you have verified it belongs to that person. A local signature (`gpg --lsign-key <fingerprint>`) is enough if you don't want to publish your signature.

Leave **Ownertrust** alone unless you have a reason to change it. Ownertrust sets how far you trust that person to vouch for *other people's* keys; it doesn't confirm that the key is theirs. Signing the key is what does that.

## Command-line equivalents

```sh
# Create a signing key (replace the name, address and expiry)
gpg --quick-generate-key "Your Name <you@example.com>" ed25519 cert,sign 2y

# Find the fingerprint of the new key
gpg --list-secret-keys --keyid-format LONG

# Add an encryption subkey
gpg --quick-add-key <FINGERPRINT> default encrypt 2y

# Publish to keys.openpgp.org (it replies with a verification link)
gpg --export you@example.com | curl -T - https://keys.openpgp.org

# Back up the private key (store the file offline)
gpg --export-secret-keys --armor <FINGERPRINT> > private-key-backup.asc

# Import someone else's key, check its fingerprint, then sign it locally
gpg --keyserver hkps://keys.openpgp.org --search-keys them@example.com
gpg --fingerprint them@example.com
gpg --lsign-key <THEIR FINGERPRINT>
```

Expiry periods use `d` for days, `w` for weeks, `m` for months and `y` for years. Omit the expiry to use the default. Use a short expiry such as `1d` only for a test key.
