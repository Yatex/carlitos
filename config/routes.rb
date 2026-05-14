Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "auth/google", to: "google_auth#start", as: :google_auth
  get "auth/google/callback", to: "google_auth#callback", as: :google_auth_callback

  resources :password_resets, only: [:new, :create], param: :token
  get "password_resets/:token/edit", to: "password_resets#edit", as: :edit_password_reset
  patch "password_resets/:token", to: "password_resets#update", as: :password_reset

  resource :account, only: [:edit, :update]
  resource :settings, only: [:show], controller: :settings
  post "settings/integrations/:provider/connect", to: "integration_connections#create", as: :connect_integration
  delete "settings/integrations/:provider", to: "integration_connections#destroy", as: :disconnect_integration
  get "integrations/google/callback", to: "google_oauth_callbacks#show", as: :google_oauth_callback
  get "dashboard", to: "dashboard#show", as: :dashboard

  namespace :admin do
    root to: redirect("/admin/users")
    resources :users, only: [:index] do
      member do
        patch :extend_plan
        patch :update_role
      end
    end
    get "analytics", to: "analytics#index", as: :analytics
  end

  resources :reminders, only: [:index, :new, :create, :update]
  resources :memory_lists, only: [:index, :show, :new, :create] do
    resources :memory_list_items, only: [:create, :update]
  end
  resources :memory_notes, only: [:index, :new, :create]
  resource :daily_briefing, only: [:edit, :update]

  resource :billing, only: [:show], controller: :billing
  post "billing/checkout", to: "stripe_checkouts#create", as: :stripe_checkout
  post "billing/portal", to: "stripe_portals#create", as: :stripe_portal
  post "stripe/webhooks", to: "stripe_webhooks#create", as: :stripe_webhooks

  namespace :whatsapp do
    post "inbound", to: "inbound#create"
  end

  resources :early_access_signups, only: [:create]
end
