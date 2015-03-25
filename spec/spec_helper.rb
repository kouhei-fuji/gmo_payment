# coding: utf-8
require 'simplecov'
require 'coveralls'
Coveralls.wear!
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter 'spec'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gmo_payment'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
RSpec.configure do |c|
  c.raise_errors_for_deprecations!
  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").gsub(/[^\w\/]+/, "_")
    VCR.use_cassette(name) { example.call }
  end
end

require 'webmock/rspec'
require 'vcr'
PREFIX = 'GMO_TEST_'
VCR.configure do |c|
  c.filter_sensitive_data('<API_ENDPOINT>') do
    ENV["#{PREFIX}API_ENDPOINT"]
  end
  c.filter_sensitive_data('<SITE_ID>') do
    ENV["#{PREFIX}SITE_ID"]
  end
  c.filter_sensitive_data('<SITE_PASS>') do
    ENV["#{PREFIX}SITE_PASS"]
  end
  c.filter_sensitive_data('<SHOP_ID>') do
    ENV["#{PREFIX}SHOP_ID"]
  end
  c.filter_sensitive_data('<SHOP_PASS>') do
    ENV["#{PREFIX}SHOP_PASS"]
  end
  c.filter_sensitive_data('<CARD_EXPIRE>') do
    ENV["#{PREFIX}CARD_EXPIRE"]
  end
  c.filter_sensitive_data('<CARD_NO_N>') do
    ENV["#{PREFIX}CARD_NO_N"]
  end
  c.filter_sensitive_data('<CARD_NO_N_MASK>') do
    ENV["#{PREFIX}CARD_NO_N_MASK"]
  end
  c.filter_sensitive_data('<CARD_NO_Y>') do
    ENV["#{PREFIX}CARD_NO_Y"]
  end
  c.filter_sensitive_data('<CARD_NO_Y_MASK>') do
    ENV["#{PREFIX}CARD_NO_Y_MASK"]
  end
  c.filter_sensitive_data('<ACS_URL>') do
    ENV["#{PREFIX}ACS_URL"]
  end
  c.filter_sensitive_data('<BTC_URL>') do
    ENV["#{PREFIX}BTC_URL"]
  end

  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
end
