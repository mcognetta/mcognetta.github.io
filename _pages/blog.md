---
title:  "Theoretically Good With Computers"
layout: archive
permalink: /Blog/
author_profile: true
comments: true
---

Below are recent posts from my CS blog. Constructive feedback is always appreciated.

<h3 class="archive__subtitle">{{ site.data.ui-text[site.locale].recent_posts | default: "Recent Posts" }}</h3>
{% for post in site.categories.cs %}
  {% include archive-single.html %}
{% endfor %}