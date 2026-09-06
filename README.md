# KQL Field Notes

A Jekyll site for practical Kusto Query Language notes and related work reference material.

## GitHub Pages

The site is intentionally served from `docs/`. In the repository settings, configure GitHub Pages to deploy from the publishing branch and the `/docs` folder.

For a custom domain, replace `url` in `_config.yml` with the canonical HTTPS URL and leave `baseurl` empty. Add a `docs/CNAME` file containing the domain only when the domain is ready to be connected.

For a project site without a custom domain, set `url` to the GitHub Pages URL and set `baseurl` to `/<repository-name>`.

## Local preview

Install Ruby and Bundler, then run:

```sh
bundle install
bundle exec jekyll serve --source docs
```

Open `http://localhost:4000` in a browser.

## Adding a note

Create a Markdown file in `docs/_posts/` using the `YYYY-MM-DD-title.md` naming convention. Start with front matter like this:

```yaml
---
layout: post
title: A useful query title
description: A one-sentence summary.
date: 2026-09-06
categories:
  - category
---
```

The example post in `docs/_posts/` demonstrates the expected structure for query, context, and notes.
