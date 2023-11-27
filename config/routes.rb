# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'

  post '/make_my_box' => 'home#make_my_box', as: :make_my_box
  get '/check_box_status' => 'home#check_box_status', as: :check_box_status
  get '/download' => 'home#download', as: :download
end
