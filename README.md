# README

This app was made using **Ruby 3.2.2** and **Rails 7.1.3**. There is no database used. It was built and tested on a **M1 CPU Macbook running Sonoma 14.6.1**.


### To start the app
```
git clone git@github.com:igerstel/weather.git
bundle install
rails s
```

For caching to work (start redis in a new tab):
```
rails dev:cache
redis-server
```

To run the test suite:
```
rspec spec
```

### What it does
This app takes a zip code (validated to 5 digits on the front- and back-end), and then calls up to 2 Weather Services to get current data and 5-day highs/lows. The first weather service is **WeatherApi**. If that fails or gives a bad response, the fallback service is **OpenWeatherMap**. If both fail, an error message is returned.

API keys for both services are stored in **Rails.application.credentials.weather_api** and **Rails.application.credentials.open_weather_map**.

The data is serialized for the same output but the steps are different. Results and errors are shown on the front-end via AJAX. **Redis** is used to cache data by zip code for 30 minutes, and when cached data is used, the text "loaded from cache" will appear below the table.

The JSON response sent is in the form of:
```
{
  now: {
    temp: <Integer>,
    description: <String>
  },
  daily: {
    '09-26' <current day>: {
      high: <Integer>,
      low: <Integer>
    },
    ... the next 4 days (ex: keys '09-27', ... '09-30') with { high, low }
  }
}
```
In the case of an error it is simply:
```
{ error: <String> }
```


### API Documentation

#### OpenWeatherMap

**Homepage**: [https://openweathermap.org/](https://openweathermap.org/)

**API**: [https://openweathermap.org/api/one-call-3#how](https://openweathermap.org/api/one-call-3#how)

#### WeatherAPI
**Homepage**: [https://www.weatherapi.com/](https://www.weatherapi.com/)

**API (Swagger)**: [https://app.swaggerhub.com/apis-docs/WeatherAPI.com/WeatherAPI/1.0.2#/APIs/forecast-weather](https://app.swaggerhub.com/apis-docs/WeatherAPI.com/WeatherAPI/1.0.2#/APIs/forecast-weather)

---

**Requirements:**
* Must be done in Ruby on Rails
* Accept an address as input
* Retrieve forecast data for the given address. This should include, at minimum, the current temperature (Bonus points - Retrieve high/low and/or extended forecast)
* Display the requested forecast details to the user
* Cache the forecast details for 30 minutes for all subsequent requests by zip codes.
Display indicator if result is pulled from cache.
Assumptions:
* This project is open to interpretation
* Functionality is a priority over form
* If you get stuck, complete as much as you can
Submission:
* Use a public source code repository (GitHub, etc) to store your code
* Send us the link to your completed code
