# frozen_string_literal: true

require_relative "lib/hyperdx/ruby/version"

Gem::Specification.new do |spec|
  spec.name = "hyperdx-ruby"
  spec.version = Hyperdx::VERSION
  spec.authors = ["Warren Lee"]
  spec.email = ["warren@hyperdx.io"]

  spec.summary = "HyperDX Ruby SDK"
  spec.description = ""
  spec.homepage = "https://github.com/hyperdxio/hyperdx-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.glob("{lib}/**/*.rb") + %w[LICENSE README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "require_all", "~> 1.4"

  spec.add_development_dependency "minitest", "~> 5.18"
  spec.add_development_dependency "rubocop", "~> 0.78"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
