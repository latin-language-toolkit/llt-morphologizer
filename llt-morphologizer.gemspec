# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'llt/morphologizer/version'

Gem::Specification.new do |spec|
  spec.name          = "llt-morphologizer"
  spec.version       = LLT::Morphologizer::VERSION
  spec.authors       = ["LFDM"]
  spec.email         = ["1986gh@gmail.com"]
  spec.summary       = %q{Morphological parsing of Latin forms}
  spec.description   = spec.summary
  spec.homepage      = "http://www.latin-language-toolkit.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_development_dependency "llt-db_handler-stub"

  spec.add_dependency "llt-constants"
  spec.add_dependency "llt-core"
  spec.add_dependency "llt-core_extensions"
  spec.add_dependency "llt-db_handler"
  spec.add_dependency "llt-form_builder"
  spec.add_dependency "llt-helpers"
  spec.add_dependency "llt-logger"
end
