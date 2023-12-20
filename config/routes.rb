Rails.application.routes.draw do
  scope '/geolocations' do
    get '', to: 'geolocations#show'
    post '', to: 'geolocations#fetch_and_create'
    delete '', to: 'geolocations#destroy'
  end
end
