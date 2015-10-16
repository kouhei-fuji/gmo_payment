# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gmo_payment/version'

Gem::Specification.new do |spec|
  spec.name          = 'gmo_payment'
  spec.version       = GmoPayment::VERSION
  spec.authors       = ['Kouhei Fujigaya']
  spec.email         = ['kouhei.fujigaya@gmail.com']
  spec.summary       = %q{Ruby client for GMO-PG API.}
  spec.description   = %q{Ruby client for the protocol type API provided by GMO Payment Gateway.}
  spec.homepage      = 'https://github.com/kouhei-fuji/gmo_payment'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'
end
