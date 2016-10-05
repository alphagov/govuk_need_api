ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'mocha/setup'

require 'webmock/test_unit'
WebMock.disable_net_connect!(allow: %r{http://localhost:9200/maslow_test(/|$)})

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods

  setup do
    session = Mongoid::Sessions.default
    session.with(database: :admin).command({ setParameter: 1, textSearchEnabled: true })
  end

  teardown do
    DatabaseCleaner.clean
  end

  def stub_user
    @stub_user ||= create(:user, name: 'Stub User')
  end

  def login_as_stub_user
    login_as stub_user
  end

  def login_as(user)
    request.env['warden'] = stub(
      authenticate!: true,
      authenticated?: true,
      user: user
    )
  end
end
