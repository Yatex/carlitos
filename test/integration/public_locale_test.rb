require "test_helper"

class PublicLocaleTest < ActionDispatch::IntegrationTest
  test "landing page can render in English" do
    get root_path(locale: "en")

    assert_response :success
    assert_includes response.body, "Carlitos remembers for you."
    assert_includes response.body, "How it works"
    refute_includes response.body, "Carlitos se acuerda por vos."
  end

  test "landing page keeps Spanish as default" do
    get root_path(locale: "es")

    assert_response :success
    assert_includes response.body, "Carlitos se acuerda por vos."
    assert_includes response.body, "Cómo funciona"
    refute_includes response.body, "Carlitos remembers for you."
  end

  test "auth page switches Google copy by locale" do
    get login_path(locale: "en")

    assert_response :success
    assert_includes response.body, "Sign in with Google"
    refute_includes response.body, "Entrar con Google"
  end
end
