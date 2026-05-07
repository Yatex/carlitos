require "test_helper"

class TimezoneDetectionTest < ActionDispatch::IntegrationTest
  test "signup form includes browser timezone detection while keeping select editable" do
    get signup_path

    assert_response :success
    assert_includes response.body, 'data-controller="timezone-detect"'
    assert_includes response.body, "La detectamos desde tu navegador"
    assert_includes response.body, 'value="America/Montevideo"'
  end
end
