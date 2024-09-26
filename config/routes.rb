Rails.application.routes.draw do
  get '/weather', to: 'weather#new', as: 'weather'
  post '/weather', to: 'weather#fetch', as: 'fetch'

  root "weather#new"
end
