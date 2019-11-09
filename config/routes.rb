Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  root 'home#index', as: 'root'
  post '/processing' => 'home#processing', as: 'processing'
  get '/download' => 'home#download', as: 'download'
end
