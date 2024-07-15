# frozen_string_literal: true

require 'sidekiq/web'
require 'devise/rails/routes'

Rails.application.routes.draw do
  devise_for :users

  root 'home#index', as: 'home'

  resource :boxes, only: [:new, :create, :show] do
    get :check_job_status
  end

  namespace :user do
    root to: 'boxes#new'
  end

  mount Sidekiq::Web => '/sidekiq'
end
