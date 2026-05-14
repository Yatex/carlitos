require "test_helper"

class GoogleAccountProvisionerTest < ActiveSupport::TestCase
  test "rejects unverified google email" do
    error = assert_raises(Authentication::GoogleAccountProvisioner::ProvisionError) do
      Authentication::GoogleAccountProvisioner.new.call(
        profile: {
          "sub" => "unverified",
          "email" => "unverified@example.com",
          "email_verified" => false
        },
        timezone: "America/Montevideo"
      )
    end

    assert_match "confirmó", error.message
  end
end
