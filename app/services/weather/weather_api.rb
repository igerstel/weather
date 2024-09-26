module Weather::WeatherApi
  KEY = Rails.application.credentials.weather_api
  URL = "http://api.weatherapi.com/v1/forecast.json"

  # Calls WeatherApi API to find forecast info and return JSON + code
  #
  # @param [String] 5-digit zipcode
  # @return [Array<(Hash, Integer)>] An array containing the response body as a hash and the status code as an integer
  def self.call(zip)
    # get temperature in Fahrenheit
    uri = URI.parse(URL + "?q=#{zip}&key=#{KEY}&days=5&aqi=no&alerts=no")

    # Fail gracefully if the external API is down
    begin
      resp = JSON(Net::HTTP.get(uri))
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("HTTP error reaching WeatherApi: #{e.message}")
      return { error: 'Timeout connecting to WeatherApi' }, 408
    rescue StandardError => e
      Rails.logger.error "HTTP request failed: #{e.message}"
      return { error: 'Error from WeatherApi' }, 500
    end

    if resp['error']
      Rails.logger.error("Error reaching WeatherApi: #{resp['error']['code']}: #{resp['error']['message']}")
      return { error: resp['error']['message'] }, resp['error']['code']
    end

    # now + 5-day forecast
    forecast = package_forecast(resp)

    return forecast, 200
  end

  # Compiles forecast data (in local timezone)
  #
  # @param [Array<Hash>] list of forecast data (5 days)
  # @return [Hash] the response body as a hash of current ('now') data and a 5-day ('daily') forecast array
  def self.package_forecast(data)
    forecast = { 'now' => {}, 'daily' => {} }

    forecast['now'] = package_current_forecast(data['current'])

    # d['date'] key example '2024-09-26' -> '09-26'
    # each loop is 1 day
    data['forecast']['forecastday'].each do |d|
      forecast['daily'][d['date'][5..-1]] = package_daily_forecast(d)
    end

    return forecast
  end

  def self.package_current_forecast(data_point)
    {
      'temp' => data_point['temp_f'].to_f.round,
      'description' => data_point['condition']['text'].downcase
    }
  end

  def self.package_daily_forecast(data_point)
    {
      'high' => data_point['day']['maxtemp_f'].to_f.round,
      'low' => data_point['day']['mintemp_f'].to_f.round
    }
  end
end
