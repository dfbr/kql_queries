---
layout: default
title: KQL Field Notes
---

<section class="intro">
  <p class="eyebrow">Kusto Query Language</p>
  <h1>Queries for the work in front of me.</h1>
  <p class="lede">A growing reference of practical KQL patterns, investigations, and notes for working with operational data.</p>
</section>

<section class="post-list" aria-labelledby="recent-heading">
  <div class="section-heading">
    <h2 id="recent-heading">Recent notes</h2>
    <a href="{{ '/feed.xml' | relative_url }}">RSS feed</a>
  </div>

  {% assign entries = site.posts | concat: site.notes %}
  {% if entries.size > 0 %}
    {% for post in entries reversed %}
      <article class="post-preview">
        <p class="post-meta">{{ post.date | date: "%d %b %Y" }}{% if post.categories.size > 0 %} · {{ post.categories | join: ", " }}{% endif %}</p>
        <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
        {% if post.description %}<p>{{ post.description }}</p>{% else %}{{ post.excerpt | strip_html | truncatewords: 30 }}{% endif %}
      </article>
    {% endfor %}
  {% else %}
    <p>No notes have been published yet.</p>
  {% endif %}
</section>
