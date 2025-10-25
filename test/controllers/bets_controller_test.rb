require "test_helper"

class BetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get bets_index_url
    assert_response :success
  end
end
