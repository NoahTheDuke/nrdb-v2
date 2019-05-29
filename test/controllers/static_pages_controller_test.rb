require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  it 'should get root' do
    get root_path
    assert_response :success
    assert_select 'title', 'Android: Netrunner Cards and Deckbuilder'
  end

  it 'should get help' do
    get help_path
    assert_response :success
    assert_select 'title', 'Help | NetrunnerDB'
  end

  it 'should get cards' do
    get cards_path
    assert_response :success
    assert_select 'title', 'Cards | NetrunnerDB'
  end

  it 'should get contact' do
    get contact_path
    assert_response :success
    assert_select 'title', 'Contact | NetrunnerDB'
  end
end
