require_relative '../test_helper'

class NeedsControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user

    FactoryGirl.create(:organisation, slug: "cabinet-office")
    FactoryGirl.create(:organisation, slug: "department-for-transport")
  end

  context "GET index" do
    setup do
      @needs = FactoryGirl.create_list(:need, 5)
    end

    should "return a success status" do
      get :index

      assert_response :success

      body = JSON.parse(response.body)
      assert_equal "ok", body["_response_info"]["status"]
    end

    should "return a response containing needs" do
      get :index

      body = JSON.parse(response.body)
      body["results"].sort_by! {|r| r["id"] }

      assert_equal 5, body["results"].size
      assert_equal @needs.first.need_id, body["results"][0]["id"]
      assert_equal @needs.first.role, body["results"][0]["role"]
      assert_equal @needs.first.goal, body["results"][0]["goal"]
      assert_equal @needs.first.benefit, body["results"][0]["benefit"]
    end

    should "set cache-control headers to zero" do
      get :index

      assert_equal "max-age=0, public", response.headers["Cache-Control"]
    end
  end

  context "POST create" do
    context "given a valid need" do
      setup do
        @need = {
          role: "user",
          goal: "find my local council",
          benefit: "contact them about a local enquiry",
          organisation_ids: ["cabinet-office","department-for-transport"],
          justifications: ["legislation","other"],
          impact: "Noticed by an expert audience",
          met_when: ["criteria #1","criteria #2"],
          monthly_user_contacts: 1000,
          monthly_site_views: 10000,
          monthly_need_views: 1000,
          monthly_searches: 2000,
          currently_met: false,
          other_evidence: "Other evidence",
          legislation: "Sale of Pugs Act 2004"
        }
      end

      context "given author details" do
        setup do
          @need_with_author = @need.merge(author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          })
        end

        should "persist the need and create a revision given author information" do
          post :create, @need_with_author

          need = Need.first

          assert_equal 1, Need.count
          assert_equal "user", need.role
          assert_equal "find my local council", need.goal
          assert_equal "contact them about a local enquiry", need.benefit
          assert_equal ["cabinet-office", "department-for-transport"], need.organisation_ids
          assert_equal ["legislation", "other"], need.justifications
          assert_equal "Noticed by an expert audience", need.impact
          assert_equal ["criteria #1", "criteria #2"], need.met_when
          assert_equal 1000, need.monthly_user_contacts
          assert_equal 10000, need.monthly_site_views
          assert_equal 1000, need.monthly_need_views
          assert_equal 2000, need.monthly_searches
          assert_equal false, need.currently_met
          assert_equal "Other evidence", need.other_evidence
          assert_equal "Sale of Pugs Act 2004", need.legislation

          assert_equal 1, need.revisions.count
          assert_equal "create", need.revisions.first.action_type
          assert_equal "Winston Smith-Churchill", need.revisions.first.author["name"]
          assert_equal "winston@alphagov.co.uk", need.revisions.first.author["email"]
        end

        should "return a created status" do
          post :create, @need_with_author

          assert_response :created

          body = JSON.parse(response.body)
          assert_equal "created", body["_response_info"]["status"]
        end

        should "return details about the new need" do
          post :create, @need_with_author

          need = Need.first
          body = JSON.parse(response.body)

          assert_equal need.need_id, body["id"]
          assert_equal "user", body["role"]
          assert_equal "find my local council", body["goal"]
          assert_equal "contact them about a local enquiry", body["benefit"]
        end
      end


      context "when no author details are provided" do
        should "return a 422 status code" do
          post :create, @need

          assert_equal 422, response.status
        end

        should "return an error in the json response" do
          post :create, @need

          body = JSON.parse(response.body)
          assert_equal "author_not_provided", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal "Author details must be provided", body["errors"].first
        end

        should "not create the need" do
          post :create, @need

          assert_equal 0, Need.count
        end
      end

      should "only pass through selected fields for an author" do
        Need.any_instance.expects(:save_as).with(
          "name" => "name",
          "email" => "email",
          "uid" => "uid"
        ).returns(true)

        post :create, @need.merge(author: {
          name: "name",
          foo: "foo",
          uid: "uid",
          email: "email",
          bar: "bar"
        })

        assert_equal 201, response.status
      end
    end

    context "given invalid attributes" do
      setup do
        @need = {
          role: "user",
          goal: "",
          benefit: "contact them about a local enquiry"
        }
      end

      context "given author details" do
        setup do
          @need_with_author = @need.merge(author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          })
        end

        should "return a 422 status code" do
          post :create, @need_with_author

          assert_equal 422, response.status
        end

        should "return model errors in the json response" do
          post :create, @need_with_author

          body = JSON.parse(response.body)
          assert_equal "invalid_attributes", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal "Goal can't be blank", body["errors"].first
        end
      end

      context "without author details" do
        should "return a 422 status code" do
          post :create, @need

          assert_equal 422, response.status
        end

        should "return an error in the json response" do
          post :create, @need

          body = JSON.parse(response.body)
          assert_equal "author_not_provided", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal "Author details must be provided", body["errors"].first
        end
      end
    end
  end

end
