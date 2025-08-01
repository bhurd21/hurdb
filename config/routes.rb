Rails.application.routes.draw do
  root 'home#index'

  resource :session
  resources :passwords, param: :token
  
  get 'api/imgrid', to: 'api#imgrid'

  get 'utility_man', to: redirect('https://chromewebstore.google.com/detail/utility-man/odpgppmidhpfpjdkoikeheciidiokomd')
  get 'utility_man/overview', to: 'home#substack_article'
  get 'utility_man/privacy_policy', to: 'home#privacy_policy'
  get 'utility_man/unsolvable_cell_notice', to: 'home#unsolvable_cell_notice'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
