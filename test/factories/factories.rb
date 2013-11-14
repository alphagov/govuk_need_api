FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Winston #{n}"}
    permissions { ["signin"] }
  end

  factory :organisation do
    name "Ministry of Plenty"
    slug "ministry-of-plenty"
    abbreviation "MOP"
    parent_ids ["ministry-of-much"]
    child_ids ["ministry-of-a-lot", "ministry-of-much"]
    govuk_status "live"
    _id { slug }
  end

  factory :need do
    role "user"
    goal "pay my council tax"
    benefit "I don't receive a fine"

    justifications [ "legislation", "other" ]
    impact "Has serious consequences for the day-to-day lives of your users"
    met_when ["user can pay their council tax"]

    monthly_user_contacts 300
    monthly_site_views 100000
    monthly_need_views 20000
    monthly_searches 6000

    currently_met false
    other_evidence "This is important"
    legislation "Council Tax Act 1994"
  end

  factory :need_revision do
    need
    action_type "update"
    snapshot { need.attributes }
    author({
      name: "Winston Smith-Churchill"
    })
  end
end
