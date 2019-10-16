# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-theme-kindee-simple"
  spec.version       = "0.1.9"
  spec.authors       = ["hatakawas"]
  spec.email         = ["hatakawas@163.com"]

  spec.summary       = "Jekyll-theme-kindee-simple is a simple but not simple theme for jekyll."
  spec.homepage      = "https://github.com/hatakawas/jekyll-theme-kindee-simple.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README)/|\.(txt|md|markdown|html)$!i) }

  spec.add_runtime_dependency "jekyll", "~> 4.0"
  spec.add_runtime_dependency "jekyll-feed", "~> 0.11"
  spec.add_runtime_dependency "jekyll-sitemap", "~> 1.2"
  spec.add_runtime_dependency "jekyll-seo-tag", "~> 2.5"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
end
