require 'socket'

class GeolocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_endpoint, only: %i[ show fetch_and_create destroy ]
  before_action :set_geolocation, only: %i[ show destroy ]
  wrap_parameters false

  # GET /geolocations?endpoint=127.0.0.1
  # GET /geolocations?endpoint=www.example.com
  def show
    if @geolocation.nil?
      logger.info("Geolocation not found for #{params[:endpoint]}")
      render status: :not_found
    else
      logger.info("Geolocation found for #{params[:endpoint]}")
      render json: @geolocation
    end
  end

  # POST /geolocations
  # {
  #  "endpoint": "1.1.1.1"
  # }
  def fetch_and_create
    ip = convert_endpoint_to_ip(geolocation_params[:endpoint])
    begin
      @geolocation = GeolocationAdapter.fetch_geolocation(ip)
    rescue GeolocationAdapter::GeolocationServiceError => e
      logger.error("Failed to fetch geolocation from external service: #{e.message}")
      logger.error e.backtrace.join("\n")
      render json: { error: "Failed to fetch geolocation from external service: #{e.message}" }, status: 503 and return
    end

    if @geolocation.save
      logger.info("Geolocation saved for #{params[:endpoint]}")
      render json: @geolocation, status: :created
    else
      logger.error("Failed to save Geolocation #{@geolocation.errors.full_messages}")
      render json: @geolocation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /geolocations?endpoint=127.0.0.1
  # DELETE /geolocations?endpoint=www.example.com
  def destroy
    if @geolocation.nil?
      logger.info("Geolocation not found for #{params[:endpoint]}")
      render status: :not_found
    else
      @geolocation.destroy!
      logger.info("Geolocation deleted for #{params[:endpoint]}")
    end
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
    logger.info("Converted ip: #{converted_ip} for #{params[:endpoint]}")

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

    begin
      IPSocket::getaddress(endpoint)
    rescue SocketError => e
      logger.error("Failed to get ip address: #{e.message}")
      logger.error e.backtrace.join("\n")
      raise ActionController::BadRequest.new("Invalid endpoint(url) is provided")
    end
  end
end
