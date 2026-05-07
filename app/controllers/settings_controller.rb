class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @integration_cards = Integrations::Catalog.cards_for(current_user)
  end
end
