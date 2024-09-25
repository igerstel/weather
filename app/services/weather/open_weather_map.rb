class OpenWeatherMap < Weather
  KEY = Rails.application.credentials.open_weather_map
  URL = "https://api.openweathermap.org/data/2.5/forecast"

  def get_forecast(zip)
    # get temperature in Fahrenheit: units=imperial
    uri = URI.parse(URL + "?zip=#{zip},US&appid=#{KEY}4&units=imperial")
    resp = JSON(Net::HTTP.get(uri))

    if resp['cod'] != 200
      Rails.logger.error("Error reaching OpenWeatherMap: #{resp['cod']}: #{resp['message']}")
      return { error: resp['message'] }, (resp['cod'] || 404)
    end

    # 5-day forecast, [0] is now in UTC. Convert to city time.
    tz = resp['city']['timezone'] / 3600
    forecast = package_forecast(resp['list'], tz)

    return forecast, 200
  end

  def package_forecast(data, tz)
    forecast = { 'now' => {}, 'daily' => {} }

    forecast['now'] = package_hourly_forecast(data[0])

    # each loop is 3 hours
    data.each do |d|
      # ts_md key example '09-25'
      ts_md = (d['dt_txt'].to_datetime + tz.hours).strftime("%m-%d")

      # calculate daily high and low by comparing each min/max value
      forecast['daily'][ts_md] = package_daily_forecast(d, forecast['daily'][ts_md])
    end

    return forecast
  end

  # def package_hourly_forecast(data_point)
  def package_current_forecast(data_point)
    {
      'temp' => data_point['main']['temp'].to_f.round,
      'description' => data_point['weather'][0]['description'].downcase
    }
  end

  def package_daily_forecast(data_point, day_hash)
    {
      'high' => [day_hash['high'], data_point['temp_max'].to_f.round].max,
      'low' => [day_hash['low'], data_point['temp_min'].to_f.round].min
    }
  end
end
