Rails.application.routes.draw do
  root 'home#index'
  post '/processing' => 'home#processing'
  get '/download' => 'home#download'
end
