FactoryBot.define do
  factory :user do
    username { Faker::Name.name[0...20] }
    sequence :email do |n|
      "user#{n}@example.com"
    end
    password { 'password1234' }
    password_confirmation { 'password1234' }
    admin { false }
    activated { true }
    activated_at { Time.zone.now }

    trait :activated do
      activated { true }
    end

    trait :inactive do
      activated { false }
    end

    trait :admin do
      activated { true }
      admin { true }
    end
  end
end
