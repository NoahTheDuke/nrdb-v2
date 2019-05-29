require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  it 'should get new' do
    get login_path
    assert_response :success
  end
end
