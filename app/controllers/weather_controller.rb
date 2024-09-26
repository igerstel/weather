class WeatherController < ApplicationController
  rescue_from ActionController::ParameterMissing, with: :handle_param_missing

  # GET /weather
  def new
  end

  # POST /weather or /weather.json
  def fetch
    response, code = WeatherService.new(zip_param).get_forecast
    render json: response, status: code
  end

  private

    def zip_param
      params.require(:zip)
    end

    def handle_param_missing
      render json: { error: 'Invalid zipcode' }, status: 400
    end
end
