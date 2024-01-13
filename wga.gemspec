# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wga/version'

Gem::Specification.new do |spec|
  spec.name          = "wga"
  spec.version       = Wga::VERSION
  spec.authors       = ["goredar"]
  spec.email         = ["goredar@gmail.com"]
  spec.summary       = %q{WGA - W Automation Tool}
  spec.description   = %q{wga tool provides functionality for automating routine tasks for L1 Server Support Team}
  spec.homepage      = "https://goredar.it"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", '~> 0'
  spec.add_runtime_dependency "net-ssh", '~> 3'
  spec.add_runtime_dependency "net-scp", '~> 1'
  spec.add_runtime_dependency "jira-ruby", '~> 0'
  spec.add_runtime_dependency "goredar", '~> 0'
  spec.add_runtime_dependency "wgh", '~> 0'
  spec.add_runtime_dependency "wgz", '~> 0'
  spec.add_runtime_dependency "oj", '~> 2'
  spec.add_runtime_dependency "psych", '= 2.0.8'
  spec.add_runtime_dependency "bundler", '~> 1.10'

  spec.add_development_dependency "rake", '~> 10'
end
