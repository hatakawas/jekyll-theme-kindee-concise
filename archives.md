---
layout: page
title: Archives
permalink: /archives.html
---

{% for post in site.posts %}
{% capture year %}{{ post.date | date: "%Y" }}{% endcapture %}
{% capture month %}{{ post.date | date: "%B" }}{% endcapture %}
{% capture iYear %}{{ post.previous.date | date: "%Y" }}{% endcapture %}
{% capture iMonth %}{{ post.previous.date | date: "%B" }}{% endcapture %}

{% if forloop.first %}
<h4>Year {{ iYear }}</h4>
<ul>
  {% endif %}
  <li>
    <a href="{{ post.url }}">
      <time datetime="{{ post.date | date_to_xmlschema }}" itemprop="datePublished">{{ post.date | date:
                    site.kindee.date_format }}</time> ~> <span>{{ post.title }}</span>
    </a>
  </li>

  {% if forloop.last %}
</ul>
{% else %}
{% if year != iYear %}
</ul>
<h4>Year {{ iYear }}</h4>
<ul>
  {% endif %}
  {% endif %}
  {% endfor %}
