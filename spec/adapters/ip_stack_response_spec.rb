# frozen_string_literal: true

require 'rails_helper'
require './app/adapters/geolocation_adapter'
require './app/models/geolocation'

RSpec.describe 'GeolocationAdapter::IpStackResponse' do
  describe 'given response is unsuccessful' do
    it 'raise error' do
      expect {
        GeolocationAdapter::IpStackResponse.new({
                                                  "success" => false,
                                                  "error" =>
                                                    { "code" => 101,
                                                      "type" => "invalid_access_key",
                                                      "info" => "You have not supplied a valid API Access Key. [Technical Support: support@apilayer.com]"
                                                    }
                                                })
      }.to raise_error(GeolocationAdapter::GeolocationServiceError)
    end
  end

  describe 'given response is valid' do
    it 'returns geolocation' do
      expect {
        actual = GeolocationAdapter::IpStackResponse.new({
                                                           "ip" => "142.251.215.228",
                                                           "type" => "ipv4",
                                                           "continent_code" => "NA",
                                                           "continent_name" => "North America",
                                                           "country_code" => "US",
                                                           "country_name" => "United States",
                                                           "region_code" => "WA",
                                                           "region_name" => "Washington",
                                                           "city" => "Seattle",
                                                           "zip" => "98161",
                                                           "latitude" => 47.60150146484375,
                                                           "longitude" => -122.33039855957031,
                                                           "location" => { "geoname_id" => 5809844,
                                                                           "capital" => "Washington D.C.",
                                                                           "languages" => [{ "code" => "en",
                                                                                             "name" => "English",
                                                                                             "native" => "English" }],
                                                                           "country_flag" => "https://assets.ipstack.com/flags/us.svg",
                                                                           "country_flag_emoji" => "🇺🇸",
                                                                           "country_flag_emoji_unicode" => "U+1F1FA U+1F1F8",
                                                                           "calling_code" => "1", "is_eu" => false }
                                                         })
        expect(actual.to_geolocation).to be_a(Geolocation)
      }.not_to raise_error
    end
  end
end
