lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "efficient_join/version"

Gem::Specification.new do |spec|
  spec.name          = "efficient_join"
  spec.version       = EfficientJoin::VERSION
  spec.authors       = ["Tom Morton"]
  spec.email         = ["tomm8086@googlemail.com"]

  spec.summary       = %q{.}
  spec.description   = %q{Very fast and memory-efficient way to join ruby lists of numbers and strings.}
  spec.homepage      = "https://github.com/tomm/efficient_join"
  spec.license       = "MIT"

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tomm/efficient_join.git"
  #spec.metadata["changelog_uri"] = "Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/efficient_join/extconf.rb"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rake-compiler", "~> 1.0"
end
