# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-theme-kindee-simple"
  spec.version       = "0.2.0"
  spec.authors       = ["hatakawas"]
  spec.email         = ["hatakawas@163.com"]

  spec.summary       = "Jekyll-theme-kindee-simple is a simple but not simple theme for jekyll blog. For updates, move to jekyll-theme-kindee."
  spec.homepage      = "https://github.com/hatakawas/jekyll-theme-kindee-simple.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README)!i) }

  spec.add_runtime_dependency "jekyll", ">= 3.5", "< 5.0"
  spec.add_runtime_dependency "jekyll-feed", "~> 0.12"
  spec.add_runtime_dependency "jekyll-sitemap", "~> 1.3"
  spec.add_runtime_dependency "jekyll-seo-tag", "~> 2.6"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
