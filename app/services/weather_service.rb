class WeatherService
  require 'net/http'

  def get_forecast(zip)
    if !valid_zip?(zip)
      return { error: 'Invalid zipcode' }, 400
    end

    # first check cache
    cached_forecast = Rails.cache.read(zip)
    if cached_forecast
      return cached_forecast
    end

    # next check to WeatherAPI
    forecast, code = Weather::WeatherApi.call(zip)

    # fallback check OpenWeatherMap
    if code != 200
      forecast, code = Weather::OpenWeatherMap.call(zip)
    end

    if forecast.blank?
      return { error: 'Weather service is currently down for maintenance' }, code
    end

    # save results for this zip for 30 minutes if valid
    if code == 200
      Rails.cache.write(zip, forecast, expires_in: 30.minutes)
    end

    # Note: this still could be a non-200 response, check on front-end
    return forecast
  end

  def valid_zip?(zip)
    zip.match?(/\A\d{5}\z/)
  end
end
