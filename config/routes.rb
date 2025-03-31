Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  post '/webhooks/mailgun', to: 'webhooks#mailgun'

  get '/alert_preview/:date', to: 'alert_previews#show', as: :alert_preview

  resources :alert_subscribers, only: %i[new create edit destroy update] do
    get 'confirm', on: :member

    collection do
      get '/', action: :new
    end
  end

  root to: 'alert_subscribers#new'
end
