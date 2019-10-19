---
layout: page
title: Categories
---

{%- assign all_categories = site.categories | sort -%}
{% for category in all_categories %}
{%- assign category_name = category[0] -%}
<h3 id="{{ category_name | slugify }}">
  <a href="{{ page.path }}#{{ category_name | slugify }}">{{ category_name | camelcase }}</a>
</h3>
<ul>
  {% assign posts = category[1] %}
  {% for post in posts %}
  <li>
    <a href="{{ post.url }}">
      <time datetime="{{ post.date | date_to_xmlschema }}" itemprop="datePublished">{{ post.date | date:
            site.kindee.date_format }}</time> ~> <span>{{ post.title }}</span>
    </a>
  </li>
  {% endfor %}
</ul>
{% endfor %}
