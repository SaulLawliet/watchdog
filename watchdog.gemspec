
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "watchdog/version"

Gem::Specification.new do |spec|
  spec.name          = "watchdog"
  spec.version       = Watchdog::VERSION
  spec.authors       = ["Saul Lawliet"]
  spec.email         = ["october.sunbathe@gmail.com"]

  spec.summary       = %q{IF (网页某区域有变化) THEN (提醒你)}
  spec.description   = %q{IF (网页某区域有变化) THEN (提醒你)}
  spec.homepage      = "https://github.com/SaulLawliet"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "nokogiri", "~> 1.10"
  spec.add_development_dependency "pony", "~> 1.11"
  spec.add_development_dependency "rufus-scheduler", '~> 3.6'

  # spec.add_development_dependency "pry", "~> 0.12.2"
end
