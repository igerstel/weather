# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


To run:
clone repo
bundle install
X-- rails db:migrate --X
rails s

redis?...


PUT DOCUMENTATION COMMENTS IN METHODS
RSPEC METHODS
WEBMOCK
REDIS MOCKING...

DOCUMENTATION HERE

AJAX DOM EDITING???



Requirements:
* Must be done in Ruby on Rails
* Accept an address as input
* Retrieve forecast data for the given address. This should include, at minimum, the
current temperature (Bonus points - Retrieve high/low and/or extended forecast)
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
