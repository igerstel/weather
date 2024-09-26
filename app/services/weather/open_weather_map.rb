module Weather::OpenWeatherMap
  KEY = Rails.application.credentials.open_weather_map
  URL = "https://api.openweathermap.org/data/2.5/forecast"

  # Calls OpenWeatherMap API to find forecast info and return JSON + code
  #
  # @param [String] 5-digit zipcode
  # @return [Array<(Hash, Integer)>] An array containing the response body as a hash and the status code as an integer
  def self.call(zip)
    # get temperature in Fahrenheit: units=imperial
    uri = URI.parse(URL + "?zip=#{zip},US&appid=#{KEY}&units=imperial")

    # Fail gracefully if the external API is down
    begin
      resp = JSON(Net::HTTP.get(uri))
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("HTTP error reaching OpenWeatherMap: #{e.message}")
      return { error: 'Timeout connecting to OpenWeatherMap' }, 408
    rescue StandardError => e
      Rails.logger.error "HTTP request failed: #{e.message}"
      return { error: 'Error from OpenWeatherMap' }, 500
    end

    if resp['cod'].to_i != 200
      Rails.logger.error("Error from OpenWeatherMap: #{resp['cod']}: #{resp['message']}")
      return { error: resp['message'] }, (resp['cod'] || 404)
    end

    # 5-day forecast, [0] is now in UTC. Convert to city time.
    tz = resp['city']['timezone'] / 3600
    forecast = package_forecast(resp['list'], tz)

    return forecast, 200
  end

  # Compiles forecast data (in local timezone)
  #
  # @param [Array<Hash>] list of forecast data (5 days, every 3 hours)
  # @param [Integer] hour shift from UTC to zipcode's local time
  # @return [Hash] the response body as a hash of current ('now') data and a 5-day ('daily') forecast array
  def self.package_forecast(data, tz)
    forecast = { 'now' => {}, 'daily' => {} }
    forecast['now'] = package_current_forecast(data[0])

    # each loop is 3 hours
    data.each do |d|
      # ts_md key example '09-25'
      ts_md = (d['dt_txt'].to_datetime + tz.hours).strftime("%m-%d")

      # calculate daily high and low by comparing each min/max value
      forecast['daily'][ts_md] = package_daily_forecast(d['main'], forecast['daily'], ts_md)
    end

    return forecast
  end

  def self.package_current_forecast(data_point)
    {
      'temp' => data_point['main']['temp'].to_f.round,
      'description' => data_point['weather'][0]['description'].downcase
    }
  end

  def self.package_daily_forecast(data_point, day_hash, day)
    # initialize high/low if it's a new day key
    if day_hash[day].blank?
      {
        'high' => data_point['temp_max'].to_f.round,
        'low' => data_point['temp_min'].to_f.round
      }
    else
      {
        'high' => [day_hash[day]['high'], data_point['temp_max'].to_f.round].max,
        'low' => [day_hash[day]['low'], data_point['temp_min'].to_f.round].min
      }
    end
  end
end
