require 'stock_quote'
require 'rubygems'
require 'bundler/setup'
require 'support/vcr'

VCR.configure do |config|
  config.configure_rspec_metadata!
end
