# README

### Ruby version

* 3.1.2

### Rails version

* 7.1.2

### Prerequisites

- Docker

### Run the app in development mode with docker (Recommended)

- **Make sure you replace `{{YOUR_ACCESS_KEY}}` with your own ipstack access key in `docker-compose.yml` file**
- Run the following commands in the root directory of the project

```bash
docker-compose build rails
docker-compose up
```

- You can now access the app at http://localhost:3000
- Code change on local machine will be reflected in the container automatically

### Database

- For the purpose of this test, I used sqlite3 as the database. So no need to setup any database.

#### Database initialization

- Run the following commands in the root directory of the project

```bash
docker-compose run rails rails db:setup
```

- You will have some sample data in the database
    - 5 Geolocations
    - 1 User
- You can also run the following command to reset the database

```bash
docker-compose run rails rails db:reset
```

### Run the app in development mode without docker

- Make sure you have proper Ruby version installed
- Run the following commands in the root directory of the project

```bash
bundle install
export GEOLOCATION_ACCESS_KEY={{YOUR_ACCESS_KEY}}
export GEOLOCATION_URL=http://api.ipstack.com/
bin/rails server
```

### Authentication

- It uses [devise_token_auth](https://github.com/lynndylanhurley/devise_token_auth) gem for authentication
- User can login by calling auth endpoint with credentials
- To login, call the following endpoint with the credentials above

```bash
curl -sS -D - --location 'localhost:3000/auth/sign_in' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "test@test.com",
    "password": "password"
}'
```

- And you will get the authentication data similar to the following from response headers

```bash
access-token: ZgPJ4xWc79xUlX3V4NYPWw
token-type: Bearer
client: YpOjkipnOStk-1HGFvTKzA
expiry: 1704322870
uid: test@test.com
```

- You can use the above data to make authenticated requests to the app like the following

```bash
curl --location --request GET 'localhost:3000/geolocations?endpoint=1.1.1.1' \
--header 'access-token: ZgPJ4xWc79xUlX3V4NYPWw' \
--header 'client: YpOjkipnOStk-1HGFvTKzA' \
--header 'expiry: 1704322870' \
--header 'uid: test@test.com' \
--header 'Content-Type: application/json' \
--data '{
    "endpoint": "1.1.1.1"
}'
```

- Alternatively, you can signup a new user by calling the following endpoint

```bash
curl --location 'localhost:3000/auth/' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email": "foo@bar.com",
    "password": "password",
    "password_confirmation": "password"
}'
```

### API

- Make sure you have the authentication data in the request headers
- **For the brevity of this document, I will not include the authentication data in the request headers in the following
  examples**

#### Get geolocation data

- To get geolocation data, call the following endpoint with the ip address
- Below is an example of the request that gets geolocation data for ip address 1.1.1.1 which is one of the sample data
  in the database
- It doesn't involve any external api call. It just returns the data from the database

```bash
curl --location --request GET 'localhost:3000/geolocations?endpoint=1.1.1.1' \
--header 'Content-Type: application/json' \
--data '{
    "endpoint": "1.1.1.1"
}'
```

#### Create geolocation data

- To create geolocation data, call the following endpoint with the ipv4 or ipv6 or url(ex- www.google.com) in the
  request body
- Geolocation data will be created by calling the external api

```bash
curl --location 'localhost:3000/geolocations' \
--header 'Content-Type: application/json' \
--data '{
    "endpoint": "www.google.com"
}'
```

#### Delete geolocation data

- To delete geolocation data, call the following endpoint with the ipv4 or ipv6 or url in the request body

```bash
curl --location --request DELETE 'localhost:3000/geolocations' \
--header 'Content-Type: application/json' \
--data '{
    "endpoint": "www.google.com"
}'
```

### How to run the test suite

- Run the following commands in the root directory of the project

```bash
docker-compose run rails rails spec
```
