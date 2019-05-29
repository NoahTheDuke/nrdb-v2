require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  it 'index including pagination' do
    user = create(:user)
    log_in_as(user)
    50.times do
      create(:user)
    end
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    User.paginate(page: 1).each do |u|
      assert_select 'a[href=?]', user_path(u), text: u.username
    end
  end

  it 'index as admin including pagination and delete links' do
    admin = create(:user, :admin)
    non_admin = create(:user)
    log_in_as(admin)
    50.times do
      create(:user)
    end
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.username
      assert_select 'a[href=?]', user_path(user), text: 'delete' unless user == admin
    end
    assert_difference 'User.count', -1 do
      delete user_path(non_admin)
    end
  end

  it 'index as non-admin' do
    user = create(:user)
    log_in_as(user)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end
end
