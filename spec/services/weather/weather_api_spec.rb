require 'rails_helper'

RSpec.describe Weather::WeatherApi do
  let(:zip) { '90210' }
  let(:api_key) { 'dummy_key' }
  let(:url) { "http://api.weatherapi.com/v1/forecast.json?q=#{zip}&key=#{api_key}&days=5&aqi=no&alerts=no" }
  let(:good_response_body) do
    {
      'current' => {
        'temp_f' => 75.5,
        'condition' => { 'text' => 'Clear' }
      },
      'forecast' => {
        'forecastday' => [
          { 'date' => '2024-09-26', 'day' => { 'maxtemp_f' => 78, 'mintemp_f' => 65 } },
          { 'date' => '2024-09-27', 'day' => { 'maxtemp_f' => 80, 'mintemp_f' => 66 } }
        ]
      }
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:weather_api).and_return(api_key)
  end

  describe '.call' do
    context 'with a successful response' do
      it 'returns the forecast and status 200' do
        allow(Net::HTTP).to receive(:get).and_return(good_response_body.to_json)

        forecast, status = Weather::WeatherApi.call(zip)

        expect(status).to eq(200)
        expect(forecast['now']).to eq({
          'temp' => 76,  # 75.5 rounded
          'description' => 'clear'
        })
        expect(forecast['daily']['09-26']).to eq({ 'high' => 78, 'low' => 65 })
        expect(forecast['daily']['09-27']).to eq({ 'high' => 80, 'low' => 66 })
      end
    end

    context 'with a response error' do
      let(:response_body) do
        {
          'error' => {
            'code' => 418,
            'message' => 'No matching location found.'
          }
        }
      end

      it 'returns an error message and status code from the API' do
        allow(Net::HTTP).to receive(:get).and_return(response_body.to_json)

        forecast, status = Weather::WeatherApi.call(zip)

        expect(status).to eq(response_body['error']['code'])
        expect(forecast).to eq({ error: response_body['error']['message'] })
      end
    end

    context 'with a bad response' do
      it 'handles a timeout' do
        rescue_body = { error: 'Timeout connecting to WeatherApi' }
        allow(Net::HTTP).to receive(:get).and_raise(Net::ReadTimeout)
        allow(Net::HTTP).to receive(:get).and_raise(Net::ReadTimeout)

        forecast, status = Weather::WeatherApi.call(zip)

        expect(status).to eq(408)
        expect(forecast).to eq(rescue_body)
      end

      it 'returns a general error message and status 500' do
        rescue_body = { error: 'Error from WeatherApi' }
        allow(Net::HTTP).to receive(:get).and_raise(StandardError.new('some error'))

        forecast, status = Weather::WeatherApi.call(zip)

        expect(status).to eq(500)
        expect(forecast).to eq(rescue_body)
      end
    end
  end

  describe '.package_forecast' do
    let(:data) { good_response_body }

    it 'packages the forecast data correctly' do
      forecast = Weather::WeatherApi.package_forecast(data)

      expect(forecast['now']).to eq({ 'temp' => 76, 'description' => 'clear' })
      expect(forecast['daily']['09-26']).to eq({ 'high' => 78, 'low' => 65 })
      expect(forecast['daily']['09-27']).to eq({ 'high' => 80, 'low' => 66 })
    end
  end

  describe '.package_current_forecast' do
    let(:data_point) {{ 'temp_f' => 75.5, 'condition' => { 'text' => 'Clear' } }}

    it 'packages current forecast correctly' do
      current_forecast = Weather::WeatherApi.package_current_forecast(data_point)
      expect(current_forecast).to eq({ 'temp' => 76, 'description' => 'clear' })
    end
  end

  describe '.package_daily_forecast' do
    let(:data_point) {{ 'day' => { 'maxtemp_f' => 80, 'mintemp_f' => 70 } }}

    it 'packages daily forecast correctly' do
      daily_forecast = Weather::WeatherApi.package_daily_forecast(data_point)
      expect(daily_forecast).to eq({ 'high' => 80, 'low' => 70 })
    end
  end
end
