# frozen_string_literal: true

# I considered various options for designing geolocation api modules like below:
# 1. Mimicking Interface of strong typed language like Java in Ruby with class inheritance
#
# class GeolocationAdapterInterface
#  def fetch_geolocation(ip)
#     raise NotImplementedError
#   end
# end
#
# class IpStackGeolocationAdapter < GeolocationAdapterInterface
#   def fetch_geolocation(ip)
#     # ...
#   end
# end
#
# class OtherGeolocationAdapter < GeolocationAdapterInterface
#   def fetch_geolocation(ip)
#     # ...
#   end
# end
#
# 2. Using type checking gem like Sorbet/RBS
#
# interface _GeolocationAdapterInterface
#   def fetch_geolocation: (ip: String) -> GeoLocation
# end
#
# 3. Using duck typing
#
# But I intentionally chose option 3 because it is the most common way in Ruby
# And it's still possible to change service provider with minimal impact on the code
class GeolocationAdapter
  class GeolocationServiceError < StandardError; end

  class << self
    def fetch_geolocation(ip)
      begin
        ip_stack_response = connection.get("/#{ip}").body
      rescue Faraday::Error => e
        logger.error("Call to Geolocation external service failed: #{e.message}")
        raise GeolocationServiceError, e.message
      end
      IpStackResponse.new(ip_stack_response).to_geolocation

      # You can change the service provider here like below without affecting controller and model
      #
      # other_response = connection.get("/foo/#{ip}").body
      # OtherGeolocationServiceResponse.new(other_response).to_geolocation_dto
    end

    private

    def connection
      Faraday.new(
        url: ENV['GEOLOCATION_URL'],
        params: { access_key: ENV['GEOLOCATION_ACCESS_KEY'] },
      ) do |builder|
        builder.request :json
        builder.response :json
        builder.response :raise_error
        builder.response :logger
      end
    end
  end

  # This class is used to convert the response from the service provider to Geolocation model
  class IpStackResponse
    def initialize(res)
      if res["success"] == false
        raise GeolocationServiceError, "Unsuccessful response from Geolocation service"
      end

      @ip = res["ip"]
      @continent_name = res["continent_name"]
      @country_name = res["country_name"]
      @region_name = res["region_name"]
      @city = res["city"]
      @latitude = res["latitude"]
      @longitude = res["longitude"]
    end

    # It is used to decouple the service provider from the controller and model
    # It allows domain model Geolocation not to be affected by unexpected changes in the service provider response
    def to_geolocation
      Geolocation.new(
        ip_address: @ip,
        country: @country_name,
        region: @region_name,
        city: @city,
        lat: @latitude,
        lon: @longitude
      )
    end
  end
end