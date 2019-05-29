require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest
  it 'unsuccessful edit' do
    user = create(:user)
    log_in_as(user)
    get edit_user_path(user)
    assert_template 'users/edit'
    patch user_path(user), params: { user: { username: '',
                                             email: 'foo@invalid',
                                             password: 'foo',
                                             password_confirmation: 'bar' } }

    assert_template 'users/edit'
  end

  it 'successful edit with friendly forwarding' do
    user = create(:user)
    get edit_user_path(user)
    log_in_as(user)
    assert_redirected_to edit_user_url(user)
    name  = 'Foo Bar'
    email = 'foo@bar.com'
    patch user_path(user), params: { user: { username: name,
                                             email: email,
                                             password: '',
                                             password_confirmation: '' } }
    assert_not flash.empty?
    assert_redirected_to user
    user.reload
    assert_equal name, user.username
    assert_equal email, user.email
  end
end
