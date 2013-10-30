require 'simplecov'
SimpleCov.start

$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'pry'

RSpec.configure do |config|
  config.filter_run_excluding skip: true
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    I18n.locale = :en
    DatabaseCleaner.clean
  end
end

require 'mongoid'
require 'mongoid_taggable'

Mongoid.load!("spec/mongoid.yml", :test)

