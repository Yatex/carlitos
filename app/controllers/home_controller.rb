class HomeController < ApplicationController
  def index
    @early_access_signup = EarlyAccessSignup.new
  end
end
