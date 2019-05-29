require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  it 'account_activation' do
    user = create(:user)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal 'Account Activation', mail.subject
    assert_equal [user.email], mail.to
    assert_equal ['noreply@example.com'], mail.from
    assert_match user.username, mail.body.encoded
    assert_match user.activation_token, mail.body.encoded
    assert_match CGI.escape(user.email), mail.body.encoded
  end

  it 'password_reset' do
    user = create(:user)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal 'Password Reset', mail.subject
    assert_equal [user.email], mail.to
    assert_equal ['noreply@example.com'], mail.from
    assert_match user.reset_token, mail.body.encoded
    assert_match CGI.escape(user.email), mail.body.encoded
  end
end
