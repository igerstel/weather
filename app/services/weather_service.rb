class WeatherService
  require 'net/http'

  attr_accessor :zip

  SERVICES = [Weather::WeatherApi, Weather::OpenWeatherMap]

  def initialize(zip)
    @zip = zip
  end

  # Validates a zip and pulls forecast data from cache, or calls external services for data.
  # @return [Array<(Hash, Integer)>] An array containing the response body as a hash and the status code as an integer
  def get_forecast
    if !valid_zip?
      return { error: 'Invalid zipcode' }, 400
    end

    # first check cache
    cached_forecast = Rails.cache.read(zip)
    if cached_forecast
      cached_forecast['cached'] = true
      return cached_forecast
    end

    forecast, code = call_services

    # save results for this zip for 30 minutes if valid
    if code == 200
      Rails.cache.write(zip, forecast, expires_in: 30.minutes)
    end

    # Note: this still could be a non-200 response, check on front-end
    return forecast, code
  end

  def valid_zip?
    zip.match?(/\A\d{5}\z/)
  end

  # Calls SERVICES to find forecast info and return JSON + code
  # @return [Array<(Hash, Integer)>] An array containing the response body as a hash and the status code as an integer
  def call_services
    idx = 0
    code = 418  # placeholder

    while code != 200 && idx < SERVICES.count
      forecast, code = SERVICES[idx].call(zip)
      idx += 1
    end

    if forecast.blank?
      forecast = { error: 'Weather service is currently down for maintenance' }
    end

    return forecast, code
  end
end
