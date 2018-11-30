Rails.application.routes.draw do
  resources :alert_subscribers, only: %i[new create edit destroy] do
    collection do
      get '/', action: :new
    end
  end

  root to: 'alert_subscribers#new'
end
