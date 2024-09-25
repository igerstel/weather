json.extract! weather, :id, :created_at, :updated_at
json.url weather_url(weather, format: :json)
