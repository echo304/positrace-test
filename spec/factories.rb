# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { "email" }
    uid { "Doe" }
    password { "password" }
    email { "test@test.com" }
  end
end