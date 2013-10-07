FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Winston #{n}"}
    permissions { ["signin"] }
  end

  factory :organisation do
    name "Ministry of Plenty"
    slug "ministry-of-plenty"
    _id { slug }
  end

  factory :need do
    role "user"
    goal "pay my council tax"
    benefit "I don't receive a fine"
  end
end
