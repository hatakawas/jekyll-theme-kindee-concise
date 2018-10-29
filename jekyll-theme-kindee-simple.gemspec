# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-theme-kindee-simple"
  spec.version       = "0.1.0"
  spec.authors       = ["Trent Qin"]
  spec.email         = ["hatakawas@163.com"]

  spec.summary       = "Jekyll-theme-kindee-simple is a simple and plain theme for jekyll."
  spec.homepage      = "https://github.com/hatakawas/jekyll-theme-kindee-simple.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README)!i) }

  spec.add_runtime_dependency "jekyll", "~> 3.8"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
end
