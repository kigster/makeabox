# frozen_string_literal: true

require 'sidekiq/web'
require 'devise/rails/routes'

Rails.application.routes.draw do
  devise_for :users
  root 'home#index', as: 'home'

  resource :boxes do
    get :processing
    get :result
  end

  mount Sidekiq::Web => '/sidekiq'
end
