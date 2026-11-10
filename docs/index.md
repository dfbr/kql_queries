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

  {% include post-list.html page=1 %}
</section>
