require 'socket'

class GeolocationsController < ApplicationController
  before_action :validate_endpoint, only: %i[ show fetch_and_create destroy ]
  before_action :set_geolocation, only: %i[ show destroy ]
  wrap_parameters false

  # GET /geolocations?endpoint=127.0.0.1
  def show
    if @geolocation.nil?
      render status: :not_found
    else
      render json: @geolocation
    end
  end

  # POST /geolocations
  def fetch_and_create
    ip = convert_endpoint_to_ip(geolocation_params[:endpoint])
    @geolocation = GeolocationAdapter.fetch_geolocation(ip)

    begin
      if @geolocation.save
        render json: @geolocation, status: :created
      else
        render json: @geolocation.errors, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # DELETE /geolocations?endpoint=127.0.0.1
  def destroy
    @geolocation.destroy!
  end

  private

  def validate_endpoint
    case EndpointTypeFinder.call(geolocation_params[:endpoint])
    when :url
      return
    when :ipv4
      return
    when :ipv6
      return
    else
      raise ActionController::BadRequest.new("Invalid endpoint")
    end
  end

  def set_geolocation
    converted_ip = convert_endpoint_to_ip(params[:endpoint])
    @geolocation = Geolocation.find_by_ip_address(converted_ip)
  end

  def geolocation_params
    params.require(:endpoint)
    params.permit(:endpoint)
  end

  def convert_endpoint_to_ip(endpoint)
    if EndpointTypeFinder.call(endpoint) == :url
      endpoint = URI.parse(endpoint).host || endpoint
    end

    IPSocket::getaddress(endpoint)
  end
end
