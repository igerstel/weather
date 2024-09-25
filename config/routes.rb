Rails.application.routes.draw do
  get '/weather', to: 'weather#new'
  post '/weather', to: 'weather#fetch'

  root "weather#new"
end
