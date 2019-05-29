require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  describe 'Testing base helper functionality' do
    it 'full title helper' do
      assert_equal full_title, 'Android: Netrunner Cards and Deckbuilder'
      assert_equal full_title('Help'), 'Help | NetrunnerDB'
    end
  end
end
