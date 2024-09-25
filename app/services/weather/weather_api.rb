class WeatherApi < Weather
  KEY = Rails.application.credentials.weather_api
  URL = "http://api.weatherapi.com/v1/forecast.json"

  def get_forecast(zip)
    # get temperature in Fahrenheit: units=imperial
    uri = URI.parse(URL + "?q=#{zip}&key=#{KEY}&days=5&aqi=no&alerts=no")
    resp = JSON(Net::HTTP.get(uri))

    if resp['error']
      Rails.logger.error("Error reaching WeatherApi: #{resp['error']['code']}: #{resp['error']['message']}")
      return { error: resp['error']['message'] }, resp['error']['code']
    end

    # 5-day forecast
    forecast = package_forecast(resp)

    return forecast, 200
  end

  def package_forecast(data)
    forecast = { 'now' => {}, 'daily' => {} }

    forecast['now'] = package_current_forecast(data['current'])

    # d['date'] key example '2024-09-26' -> '09-26'
    # each loop is 1 day
    data['forecast']['forecastday'].each do |d|
      forecast['daily'][d['date'][5..-1]] = package_daily_forecast(d)
    end

    return forecast
  end

  def package_current_forecast(data_point)
    {
      data_point['temp_f'].to_f.round,
      data_point['condition']['text'].downcase
    }
  end

  def package_daily_forecast(data_point)
    {
      'high' => data_point['maxtemp_f'].to_f.round,
      'low' => data_point['mintemp_f'].to_f.round
    }
  end
end
