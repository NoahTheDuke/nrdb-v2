ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)

require 'rails/test_help'
require 'minitest'
require 'minitest/spec'

require 'factory_bot_rails'

class ActiveSupport::TestCase
  include ApplicationHelper
  include FactoryBot::Syntax::Methods

  # Returns true if a test user is logged in
  def logged_in?
    !session[:user_id].nil?
  end

  # Log in as a particular user
  def log_in_as(user)
    session[:user_id] = user.id
  end
end

class ActionDispatch::IntegrationTest
  # Log in as a particular user
  def log_in_as(user, password: 'password1234', remember_me: '1')
    post login_path, params: { session: { email: user.email,
                                          password: password,
                                          remember_me: remember_me } }
  end
end
