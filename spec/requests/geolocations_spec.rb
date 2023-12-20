require 'rails_helper'

RSpec.describe "Geolocations Request", type: :request do
  before(:all) do
    @current_user = FactoryBot.create(:user)
    login
    @auth_params = get_auth_params_from_login_response_headers(response)
  end

  after(:all) do
    @current_user.destroy
  end

  before(:each) do
    geolocation = Geolocation.create(
      ip_address: "2a03:2880:f101:83:face:b00c:0:25de",
      country: "Ireland",
      region: nil,
      city: nil,
      lat: 53.0,
      lon: -8.0
    )
    geolocation.save!
  end

  context "GET" do
    describe "when the Geolocation doesn't exist" do
      it "returns 404 status" do
        headers = { "ACCEPT" => "application/json" }
        get "/geolocations", :params => { :endpoint => "127.0.0.1" }, :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "when required parameter is missing" do
      it "returns 400 status" do
        headers = { "ACCEPT" => "application/json" }
        get "/geolocations", :params => { :foo => "127.0.0.1" }, :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "when the Geolocation exists and called with exact ip" do
      it "returns the Geolocation" do
        headers = { "ACCEPT" => "application/json" }
        get "/geolocations", :params => { :endpoint => "2a03:2880:f101:83:face:b00c:0:25de" }, :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body).deep_symbolize_keys
        expect(json).to include({
                                  region: nil,
                                  city: nil,
                                  country: "Ireland",
                                  ip_address: "2a03:2880:f101:83:face:b00c:0:25de",
                                  lat: "53.0",
                                  lon: "-8.0",
                                })
      end
    end

    describe "when the Geolocation exists and called with an url" do
      it "returns the Geolocation" do
        allow(IPSocket).to receive(:getaddress).and_return("2a03:2880:f101:83:face:b00c:0:25de")

        headers = { "ACCEPT" => "application/json" }
        get "/geolocations", :params => { :endpoint => "www.test.com" }, :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body).deep_symbolize_keys
        expect(json).to include({
                                  region: nil,
                                  city: nil,
                                  country: "Ireland",
                                  ip_address: "2a03:2880:f101:83:face:b00c:0:25de",
                                  lat: "53.0",
                                  lon: "-8.0",
                                })
      end
    end
  end

  context "POST" do
    describe "when the Geolocation with same ip does not exist" do
      it "creates a Geolocation and returns it" do
        allow(GeolocationAdapter).to receive(:fetch_geolocation).and_return(
          Geolocation.new(
            ip_address: "2607:f8b0:400a:80a::2004",
            country: "United States",
            region: "Washington",
            city: "Seattle",
            lat: 0.47642109e2,
            lon: -0.122406792e3,
          )
        )
        headers = { "CONTENT_TYPE" => "application/json" }
        post "/geolocations", :params => '{ "endpoint": "www.google.com" }', :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body).deep_symbolize_keys
        expect(json).to include({
                                  ip_address: "2607:f8b0:400a:80a::2004",
                                  country: "United States",
                                  region: "Washington",
                                  city: "Seattle",
                                  lat: "47.642109",
                                  lon: "-122.406792",
                                })
      end
    end

    describe "when the Geolocation with same ip exists" do
      it "returns error" do
        allow(GeolocationAdapter).to receive(:fetch_geolocation).and_return(
          Geolocation.new(
            ip_address: "2a03:2880:f101:83:face:b00c:0:25de",
            country: "Ireland",
            region: nil,
            city: nil,
            lat: 53.0,
            lon: -8.0
          )
        )
        headers = { "CONTENT_TYPE" => "application/json" }
        post "/geolocations", :params => '{ "endpoint": "www.google.com" }', :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(422)
      end
    end

    describe "when required parameter is missing" do
      it "returns 400 status" do
        headers = { "ACCEPT" => "application/json" }
        post "/geolocations", :params => '{ "foo": "www.google.com" }', :headers => headers.merge(@auth_params)

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  def login
    post user_session_path, params: { email: @current_user.email, password: 'password' }.to_json, headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
  end

  def get_auth_params_from_login_response_headers(response)
    client = response.headers['client']
    token = response.headers['access-token']
    expiry = response.headers['expiry']
    token_type = response.headers['token-type']
    uid = response.headers['uid']

    auth_params = {
      'access-token' => token,
      'client' => client,
      'uid' => uid,
      'expiry' => expiry,
      'token-type' => token_type
    }
    auth_params
  end
end
