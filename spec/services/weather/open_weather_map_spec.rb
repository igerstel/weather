require 'rails_helper'

RSpec.describe Weather::OpenWeatherMap do
  let(:zip) { '90210' }
  let(:api_key) { 'dummy_key' }
  let(:url) { "https://api.openweathermap.org/data/2.5/forecast?zip=#{zip},US&appid=#{api_key}&units=imperial" }
  let(:data) do
    [{
      'dt_txt' => '2024-09-26 12:00:00',
      'main' => { 'temp' => 75.5, 'temp_max' => 78, 'temp_min' => 73 },
      'weather' => [{ 'description' => 'clear sky' }]
    }]
  end

  before do
    allow(Rails.application.credentials).to receive(:open_weather_map).and_return(api_key)
  end

  describe '.call' do
    context 'with a successful response' do
      let(:response_body) do
        {
          'cod' => '200',
          'city' => { 'timezone' => 3600 },
          'list' => data
        }
      end

      it 'returns the forecast and status 200' do
        allow(Net::HTTP).to receive(:get).and_return(response_body.to_json)

        forecast, status = Weather::OpenWeatherMap.call(zip)

        expect(status).to eq(200)
        expect(forecast['now']).to eq({
          'temp' => 76,  # 75.5 rounded
          'description' => 'clear sky'
        })
      end
    end

    context 'with an unsuccessful response' do
      let(:response_body) do
        { 'cod' => '404', 'message' => 'city not found' }
      end

      it 'returns an error message and status code from the API' do
        allow(Net::HTTP).to receive(:get).and_return(response_body.to_json, status: 404)

        forecast, status = Weather::OpenWeatherMap.call(zip)

        expect(status).to eq('404')
        expect(forecast).to eq({ error: 'city not found' })
      end
    end

    context 'with a blank response' do
      it 'returns an error message and status code 500' do
        response_body = { 'cod' => '500', 'message' => 'unexpected response' }

        allow(Net::HTTP).to receive(:get).and_return(response_body.to_json, status: 500)

        forecast, status = Weather::OpenWeatherMap.call(zip)

        expect(status).to eq('500')
        expect(forecast).to eq({ error: 'unexpected response' })
      end
    end

    context 'with a bad response' do
      it 'handles a timeout' do
        rescue_body = { error: 'Timeout connecting to OpenWeatherMap' }
        allow(Net::HTTP).to receive(:get).and_raise(Net::ReadTimeout)

        forecast, status = Weather::OpenWeatherMap.call(zip)

        expect(status).to eq(408)
        expect(forecast).to eq(rescue_body)
      end

      it 'handles an error' do
        rescue_body = { error: 'Error from OpenWeatherMap' }

        allow(Net::HTTP).to receive(:get).and_raise(StandardError)

        forecast, status = Weather::OpenWeatherMap.call(zip)

        expect(status).to eq(500)
        expect(forecast).to eq(rescue_body)
      end
    end
  end

  describe '.package_forecast' do
    it 'packages the forecast data correctly' do
      tz = 1  # 1 hour shift from UTC
      forecast = Weather::OpenWeatherMap.package_forecast(data, tz)
      expect(forecast['now']).to eq({
        'temp' => 76,
        'description' => 'clear sky'
      })
      expect(forecast['daily']).to have_key('09-26')
      expect(forecast['daily']['09-26']).to eq({ 'high' => 78, 'low' => 73 })
    end
  end

  describe '.package_current_forecast' do
    let(:data_point) do
      {
        'main' => { 'temp' => 75.5 },
        'weather' => [{ 'description' => 'clear sky' }]
      }
    end

    it 'packages current forecast correctly' do
      current_forecast = Weather::OpenWeatherMap.package_current_forecast(data_point)
      expect(current_forecast).to eq({
        'temp' => 76,
        'description' => 'clear sky'
      })
    end
  end

  describe '.package_daily_forecast' do
    let(:data_point) { { 'temp_max' => 80, 'temp_min' => 70 } }

    context 'when day is new' do
      it 'initializes high and low temperatures' do
        daily_forecast = Weather::OpenWeatherMap.package_daily_forecast(data_point, {}, '09-26')
        expect(daily_forecast).to eq({ 'high' => 80, 'low' => 70 })
      end
    end

    context 'when day is existing' do
      it 'updates high and low temperatures based on new data' do
        day_hash = { '09-26' => { 'high' => 78, 'low' => 72 } }
        daily_forecast = Weather::OpenWeatherMap.package_daily_forecast(data_point, day_hash, '09-26')
        expect(daily_forecast).to eq({ 'high' => 80, 'low' => 70 })
      end
    end
  end
end
