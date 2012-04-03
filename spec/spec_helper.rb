require 'rspec'
require 'fakeweb'
require 'mandrill'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.before(:each) do
    FakeWeb.clean_registry
    @app_id       = 'valid-app-id'
    @api_key      = 'valid-api-key'
    @callback_url = 'https://example.com/callback'
    @error        = File.read(File.expand_path('spec/mandrill/fixtures/error.json'))
  end
end
