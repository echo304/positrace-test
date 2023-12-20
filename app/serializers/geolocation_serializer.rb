# frozen_string_literal: true

class GeolocationSerializer < ActiveModel::Serializer
  attributes :id, :ip_address, :country, :region, :city, :lat, :lon
end
