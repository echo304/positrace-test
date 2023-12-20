Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  scope '/geolocations' do
    get '', to: 'geolocations#show'
    post '', to: 'geolocations#fetch_and_create'
    delete '', to: 'geolocations#destroy'
  end
end
