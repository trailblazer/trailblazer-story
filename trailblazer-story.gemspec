lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trailblazer/story/version"

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-story"
  spec.version       = Trailblazer::Story::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]

  spec.summary       = %q{Painless test factories.}
  spec.description   = %q{Painless test factories using Trailblazer's activities.}
  spec.homepage      = "http://trailblazer.to"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-line"

  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 1.0.0", "< 2.0.0"
end
