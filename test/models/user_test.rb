require 'test_helper'

class UserTest < ActiveSupport::TestCase
  it 'should be valid' do
    user = build(:user)
    assert user.valid?
  end

  it 'authenticated? should return false for a user with nil digest' do
    user = create(:user)
    assert_not user.authenticated?(:remember, '')
  end

  describe 'usernames' do
    it 'require non-blank usernames' do
      user = build(:user, username: '')
      assert_not user.valid?
    end

    it 'limit username length' do
      user = build(:user, username: 'a' * 21)
      assert_not user.valid?

      user = build(:user, username: 'aa')
      assert_not user.valid?
    end

    it 'should be unique' do
      create(:user, username: 'noah', email: 'a@a')
      duplicate_username = build(:user, username: 'noah', email: 'b@b')
      assert_not duplicate_username.valid?
    end
  end

  describe 'emails' do
    it 'should be present (nonblank)' do
      user = build(:user, email: '')
      assert_not user.valid?
    end

    it 'should have maximum length' do
      user = build(:user, email: 'a@' + 'a' * 254)
      assert_not user.valid?
    end

    it 'require email to have text on both sides of @' do
      invalid_addresses = %w[foo@ @bar foobar]
      invalid_addresses.each do |invalid_address|
        user = build(:user, email: invalid_address)
        assert_not user.valid?, "#{invalid_address.inspect} should be invalid"
      end
    end

    it 'should be unique' do
      create(:user, username: 'noah', email: 'a@a')
      duplicate_email = build(:user, username: 'bogart', email: 'a@a')
      assert_not duplicate_email.valid?
    end
  end

  describe 'passwords' do
    it 'should be present (nonblank)' do
      pwd = ' ' * 12
      user = build(:user, password: pwd, password_confirmation: pwd)
      assert_not user.valid?
    end

    it 'should have a minimum length' do
      pwd = 'a' * 11
      user = build(:user, password: pwd, password_confirmation: pwd)
      assert_not user.valid?
    end
  end
end
