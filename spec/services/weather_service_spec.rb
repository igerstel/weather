require 'rails_helper'

RSpec.describe WeatherService do
  let(:zip) { '90210' }
  let(:invalid_zip) { '123' }
  let(:subject) { WeatherService.new(zip) }
  let(:bad_subject) { WeatherService.new(invalid_zip) }
  let(:forecast) { { 'forecast' => 'sunny', 'temperature' => 72 } }
  let(:good_resp) { [forecast, 200] }
  let(:bad_resp) { [{}, 500] }

  before do
    allow(Weather::WeatherApi).to receive(:call).and_return(good_resp)
    allow(Weather::OpenWeatherMap).to receive(:call).and_return(good_resp)
  end

  describe '#get_forecast' do
    context 'with invalid zip' do
      it 'returns an error and status 400' do
        forecast, code = bad_subject.get_forecast
        expect(forecast).to eq({ error: 'Invalid zipcode' })
        expect(code).to eq(400)
      end
    end

    context 'with valid zip' do
      before do
        Rails.cache.clear
      end

      context 'when forecast is cached' do
        let(:cached_forecast) { { 'forecast' => 'sunny', 'temperature' => 72 } }

        before do
          Rails.cache.write(zip, cached_forecast, expires_in: 30.minutes)
        end

        it 'returns the cached forecast and does not call services' do
          forecast, code = subject.get_forecast

          expect(subject).not_to receive(:call_services)
          expect(forecast).to eq(cached_forecast.merge('cached' => true))
          expect(code).to be_nil
        end
      end

      context 'when forecast is not cached' do
        it 'calls external services and returns the forecast' do
          expect(subject).to receive(:call_services).and_call_original

          forecast_result, code = subject.get_forecast

          expect(forecast_result).to eq(forecast)
          expect(code).to eq(200)
        end

        it 'caches the forecast for 30 minutes' do
          subject.get_forecast
          cached_forecast = Rails.cache.read(zip)

          expect(cached_forecast).to eq(forecast)
        end
      end
    end
  end

  describe '#valid_zip?' do
    it 'returns true for a valid zip code' do
      expect(subject.valid_zip?).to be_truthy
    end

    it 'returns false for an invalid zip code' do
      service = described_class.new(invalid_zip)
      expect(service.valid_zip?).to be_falsey
    end
  end

  describe '#call_services' do
    context 'when the first service is successful' do
      let(:forecast) { { 'forecast' => 'sunny', 'temperature' => 72 } }

      it 'returns the forecast and status code 200' do
        allow(Weather::OpenWeatherMap).to receive(:call).and_return(bad_resp)

        expect(Weather::WeatherApi).to receive(:call).with(zip).once
        expect(Weather::OpenWeatherMap).not_to receive(:call).with(zip)

        forecast_result, code = subject.call_services

        expect(forecast_result).to eq(forecast)
        expect(code).to eq(200)
      end
    end

    context 'when the first service fails but the second succeeds' do
      it 'returns the forecast and status code 200' do
        allow(Weather::WeatherApi).to receive(:call).and_return(bad_resp)

        expect(Weather::WeatherApi).to receive(:call).with(zip).once
        expect(Weather::OpenWeatherMap).to receive(:call).with(zip).once

        forecast_result, code = subject.call_services

        expect(forecast_result).to eq(forecast)
        expect(code).to eq(200)
      end
    end

    context 'when all services fail' do
      it 'returns an error message and a non-200 status code' do
        allow(Weather::WeatherApi).to receive(:call).and_return(bad_resp)
        allow(Weather::OpenWeatherMap).to receive(:call).and_return(bad_resp)

        forecast_result, code = subject.call_services

        expect(forecast_result).to eq({ error: 'Weather service is currently down for maintenance' })
        expect(code).not_to eq(200)
      end
    end
  end
end
