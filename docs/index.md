---
layout: default
title: The work in front of me
---

<section class="intro">
  <!--<p class="eyebrow">Kusto Query Language</p>-->
  <h1>The work in front of me.</h1>
  <p class="lede">Things that have been useful in my work. They may be useful in yours, or they may just help me remember what I've done.</p>
</section>

<section class="post-list" aria-labelledby="recent-heading">
  <div class="section-heading">
    <h2 id="recent-heading">Recent notes</h2>
    <a href="{{ '/feed.xml' | relative_url }}">RSS feed</a>
  </div>

  {% assign entries = site.posts | concat: site.notes %}
  {% if entries.size > 0 %}
    {% for post in entries %}
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
