class WeatherController < ApplicationController
  # GET /weather
  def new
  end

  # POST /weather or /weather.json
  def fetch
puts "------- #{weather_params.inspect}"
puts "======= #{weather_params[:zip]}"
    @weather = WeatherService.get_forecast(weather_params)
    # @weather = WeatherService.get_forecast(weather_params[:zip], weather_params[:address])

    if @weather.errors
      render json: @weather.errors, status: :unprocessable_entity
    else
      render json: @weather
    end

    # respond_to do |format|
      # if @weather.save
      #   format.html { redirect_to @weather, notice: "Weather was successfully created." }
      #   format.json { render :show, status: :created, location: @weather }
      # else
      #   format.html { render :new, status: :unprocessable_entity }
      #   format.json { render json: @weather.errors, status: :unprocessable_entity }
      # end
    # end
  end

  private

    def weather_params
      params.fetch(:weather, { :address, :zip })#, :tz })
    end
end
