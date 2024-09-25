class Weather
  require 'net/http'

  before_action :validate_zip


  def get_forecast(zip, addr=nil)
    # validate zip

    # first check cache

    # next check to WeatherAPI
    forecast, code = WeatherApi.get_forecast(zip)

    if code != 200 # or error, code, etc...
      # fallback check OpenWeatherMap
    forecast, code = OpenWeatherMap.get_forecast(zip)
puts "****************"
puts forecast.inspect
puts "****************"
    end

    # if forecast.blank?
    #   # error
    # end

    return forecast
  end

  private

    def validate_zip
      if zip&.size != 5
        Rails.logger.error("Error calling #{caller.class}: zip code #{zip.class} #{zip} is not valid")
        return { error: 'invalid zip code' }, 400
      end
    end
end
