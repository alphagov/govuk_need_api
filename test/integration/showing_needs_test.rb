require_relative '../integration_test_helper'

class ShowingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  context "retrieving a single need" do
    setup do
      FactoryGirl.create(:organisation, name: "Department for Work and Pensions", slug: "department-for-work-and-pensions")
      FactoryGirl.create(:organisation, name: "Department for Dinosaur Care", slug: "department-for-dinosaur-care")

      @need = FactoryGirl.create(:need, role: "parent",
                                        goal: "find out school holiday dates for my local school",
                                        benefit: "I can plan around the school holidays",
                                        organisation_ids: ["department-for-work-and-pensions"],
                                        need_id: 100001)
      @need.revisions.first.destroy # delete the automatically-created first revision

      @need.revisions.create!(
        author: { name: "John Hammond" },
        action_type: "update",
        snapshot: {
          role: "business owner",
          goal: "find out school holiday dates for the local schools",
          benefit: "I can open my dinosaur park in the school holidays",
          organisation_ids: ["department-for-dinosaur-care"]
        },
        created_at: Date.parse("2013-05-01")
      )

      @need.revisions.create!(
        author: { name: "Jack Torrance" },
        action_type: "create",
        snapshot: {
          role: "parent",
          goal: "find a caretaker job for the winter",
          benefit: "I can spend some time working on my writing",
          organisation_ids: []
        },
        created_at: Date.parse("2013-04-01")
      )
    end

    should "return details about the need" do
      get "/needs/100001"
      assert_equal 200, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "ok", body["_response_info"]["status"]

      assert_equal 100001, body["id"]

      assert_equal "parent", body["role"]
      assert_equal "find out school holiday dates for my local school", body["goal"]
      assert_equal "I can plan around the school holidays", body["benefit"]

      assert_equal ["department-for-work-and-pensions"], body["organisation_ids"]
      assert_equal 1, body["organisations"].size
      assert_equal "department-for-work-and-pensions", body["organisations"].first["id"]
      assert_equal "Department for Work and Pensions", body["organisations"].first["name"]
    end

    should "return revisions of the need" do
      get "/needs/100001"
      body = JSON.parse(last_response.body)

      assert_equal 2, body["revisions"].size

      update_revision = body["revisions"][0]
      expected_changes = {
        "role" => ["parent", "business owner"],
        "goal" => ["find a caretaker job for the winter", "find out school holiday dates for the local schools"],
        "benefit" => ["I can spend some time working on my writing", "I can open my dinosaur park in the school holidays"],
        "organisation_ids" => [[], ["department-for-dinosaur-care"]]
      }

      assert_equal "update", update_revision["action_type"]
      assert_equal "John Hammond", update_revision["author"]["name"]
      assert_equal expected_changes, update_revision["changes"]
      assert_equal "2013-05-01T00:00:00+00:00", update_revision["created_at"]

      create_revision = body["revisions"][1]
      expected_changes = {
        "role" => [nil, "parent"],
        "goal" => [nil, "find a caretaker job for the winter"],
        "benefit" => [nil, "I can spend some time working on my writing"],
        "organisation_ids" => [nil, []]
      }

      assert_equal "create", create_revision["action_type"]
      assert_equal "Jack Torrance", create_revision["author"]["name"]
      assert_equal expected_changes, create_revision["changes"]
      assert_equal "2013-04-01T00:00:00+00:00", create_revision["created_at"]
    end

    should "return a not found response" do
      get "/needs/42"
      assert_equal 404, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "not_found", body["_response_info"]["status"]
      assert body["error"].present?
    end
  end
end
