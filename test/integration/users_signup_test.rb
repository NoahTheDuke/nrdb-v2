require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  it 'should not create an invalid user' do
    assert_no_difference 'User.count' do
      post users_path, params: { user: { username: '',
                                         email: 'user@invalid',
                                         password: 'foo',
                                         password_confirmation: 'bar' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert'
  end

  it 'valid signup information with account activation' do
    ActionMailer::Base.deliveries.clear

    assert_difference 'User.count', 1 do
      post users_path, params: { user: { username: 'NoahBogart',
                                         email: 'nbtheduke@gmail.com',
                                         password: 'password1234',
                                         password_confirmation: 'password1234' } }
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Try to log in before activation.
    log_in_as(user)
    assert_not logged_in?
    # Invalid activation token
    get edit_account_activation_path('invalid token', email: user.email)
    assert_not logged_in?
    # Valid token, wrong email
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not logged_in?
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert logged_in?
  end
end
