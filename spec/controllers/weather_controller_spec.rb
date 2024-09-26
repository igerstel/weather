require 'rails_helper'

RSpec.describe WeatherController, type: :request do
  describe 'GET #new' do
    it 'gets new' do
      get weather_url
      expect(response).to be_successful
    end
  end

  describe 'POST #fetch' do
    it 'returns successful weather forecast from fetch' do
      mock_response = { 'forecast' => 'sunny', 'temperature' => 72 }
      mock_code = 200
      allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return([mock_response, mock_code])

      post fetch_url, params: { zip: '90210' }, as: :json

      expect(response).to be_successful
      expect(response.body).to eq(mock_response.to_json)
    end

    it 'returns error when passed a bad zip' do
      bad_zip_response = { error: 'Invalid zipcode' }
      bad_zip_code = '400'

      post fetch_url, params: { zip: '902' }, as: :json

      expect(response.body).to eq(bad_zip_response.to_json)
      expect(response.code).to eq(bad_zip_code)
    end

    it 'returns error when passed no zip' do
      bad_zip_response = { error: 'Invalid zipcode' }
      bad_zip_code = '400'

      post fetch_url, params: {}, as: :json

      expect(response.body).to eq(bad_zip_response.to_json)
      expect(response.code).to eq(bad_zip_code)
    end

    it 'returns error JSON and non-200 response code' do
      mock_response = { error: 'bad response' }
      mock_code = '401'
      allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return([mock_response, mock_code])

      post fetch_url, params: { zip: '90210' }, as: :json

      expect(response.code).to eq(mock_code)
      expect(response.body).to eq(mock_response.to_json)
    end
  end
end
