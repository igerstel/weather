class WeatherController < ApplicationController
  # GET /weather
  def new
  end

  # POST /weather or /weather.json
  def fetch
    response = WeatherService.new.get_forecast(zip_param)
    render json: response
  end

  private

    def zip_param
      params.require(:zip)
    end
end
