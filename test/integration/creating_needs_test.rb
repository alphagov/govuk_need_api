require_relative '../integration_test_helper'

class CreatingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  should "create a need given valid attributes" do
    FactoryGirl.create(:organisation, name: "Department for Work and Pensions", slug: "department-for-work-and-pensions")
    FactoryGirl.create(:organisation, name: "HM Treasury", slug: "hm-treasury")

    request_body = {
      "role" => "user",
      "goal" => "find out the minimum wage",
      "benefit" => "I can work out if I am being paid the correct amount",
      "organisation_ids" => [ "department-for-work-and-pensions", "hm-treasury" ],
      "justifications" => [ "legislation" ],
      "impact" => "Noticed by many citizens",
      "met_when" => [
        "The user sees the minimum wage",
        "The user sees information about the age groups"
      ],
      "monthly_user_contacts" => 1000,
      "monthly_site_views" => 10000,
      "monthly_need_views" => 1000,
      "monthly_searches" => 2000,
      "currently_met" => false,
      "other_evidence" => "Other evidence",
      "legislation" => "link#1\nlink#2",
      "author" => {
        "name" => "Winston Smith-Churchill",
        "email" => "winston@alphagov.co.uk"
      }
    }.to_json

    post_json '/needs', request_body
    assert_equal 201, last_response.status

    body = JSON.parse(last_response.body)
    assert_equal "created", body["_response_info"]["status"]

    assert_equal "user", body["role"]
    assert_equal "find out the minimum wage", body["goal"]
    assert_equal "I can work out if I am being paid the correct amount", body["benefit"]
    assert_equal ["department-for-work-and-pensions", "hm-treasury"], body["organisation_ids"]
    assert_equal ["legislation"], body["justifications"]
    assert_equal "Noticed by many citizens", body["impact"]
    assert_equal [ "The user sees the minimum wage", "The user sees information about the age groups" ], body["met_when"]

    assert_equal 2, body["organisations"].size
    assert_equal "Department for Work and Pensions", body["organisations"][0]["name"]
    assert_equal "department-for-work-and-pensions", body["organisations"][0]["id"]
    assert_equal "HM Treasury", body["organisations"][1]["name"]
    assert_equal "hm-treasury", body["organisations"][1]["id"]

    assert_equal 1000, body["monthly_user_contacts"]
    assert_equal 10000, body["monthly_site_views"]
    assert_equal 1000, body["monthly_need_views"]
    assert_equal 2000, body["monthly_searches"]
    assert_equal false, body["currently_met"]
    assert_equal "Other evidence", body["other_evidence"]
    assert_equal "link#1\nlink#2", body["legislation"]
  end

  should "return errors given invalid attributes" do
    request_body = {
      "role" => "user",
      "goal" => "find out the minimum wage",
      "benefit" => "",
      "author" => {
        "name" => "Winston Smith-Churchill",
        "email" => "winston@alphagov.co.uk"
      }
    }.to_json

    post_json '/needs', request_body
    assert_equal 422, last_response.status

    body = JSON.parse(last_response.body)
    assert_equal "invalid_attributes", body["_response_info"]["status"]

    assert_equal 1, body["errors"].size
    assert_equal "Benefit can't be blank", body["errors"].first
  end

  should "return errors given no author details" do
    request_body = {
      "role" => "user",
      "goal" => "find out the minimum wage",
      "benefit" => "",
      "author" => nil
    }.to_json

    post_json '/needs', request_body
    assert_equal 422, last_response.status

    body = JSON.parse(last_response.body)
    assert_equal "author_not_provided", body["_response_info"]["status"]

    assert_equal "Author details must be provided", body["errors"].first
  end

  should "refuse to create needs with an assigned ID" do
    request_body = {
      "role" => "user",
      "goal" => "find out the minimum wage",
      "benefit" => "I can work out if I am being paid the correct amount",
      "need_id" => 972
    }.to_json

    post_json '/needs', request_body
    assert_equal 422, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal ["New needs can't specify need IDs"], body["errors"]
  end
end
