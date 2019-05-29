require 'test_helper'

class SessionsHelperTest < ActionView::TestCase
  it 'current_user returns right user when session is nil' do
    user = create(:user)
    remember(user)
    assert_equal user, current_user
    assert logged_in?
  end

  it 'current_user returns nil when remember digest is wrong' do
    user = create(:user)
    remember(user)
    user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user
  end
end
