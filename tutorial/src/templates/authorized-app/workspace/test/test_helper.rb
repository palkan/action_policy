ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "action_policy/test_helper"

module ActiveSupport
  class TestCase
    parallelize(workers: 1)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include ActionPolicy::TestHelper

  def assert_text(text)
    assert_includes response.body, text
  end

  private

  def sign_in(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies[:session_id] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete(:session_id)
  end
end
