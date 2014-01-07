require_relative '../test_helper'

class NeedsControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user

    FactoryGirl.create(:organisation, slug: "cabinet-office", name: "Cabinet Office")
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

  context "GET index with search parameter" do
    setup do
      @results = [
        Search::NeedSearchResult.new(
          "need_id" => 100001,
          "role" => "fishmonger",
          "goal" => "sell fish",
          "benefit" => "earn a living",
          "organisation_ids" => ["cabinet-office"]
        )
      ]
      mock_searcher = mock("searcher")
      mock_searcher.expects(:search).with("fish").returns(@results)
      GovukNeedApi.stubs(:searcher).returns(mock_searcher)
    end

    should "return success status" do
      get :index, q: "fish"

      assert_response :success

      body = JSON.parse(response.body)
      assert_equal "ok", body["_response_info"]["status"]
    end

    should "display search results" do
      get :index, q: "fish"

      body = JSON.parse(response.body)
      assert_equal 1, body["results"].size
      assert_equal 100001, body["results"][0]["id"]
      assert_equal "fishmonger", body["results"][0]["role"]
      assert_equal "sell fish", body["results"][0]["goal"]
      assert_equal "earn a living", body["results"][0]["benefit"]
    end

    should "display organisation information" do
      get :index, q: "fish"

      body = JSON.parse(response.body)
      organisations = body["results"][0]["organisations"]
      assert_equal ["Cabinet Office"], organisations.map { |o| o["name"] }
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
          yearly_user_contacts: 1000,
          yearly_site_views: 10000,
          yearly_need_views: 1000,
          yearly_searches: 2000,
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

          GovukNeedApi.indexer.stubs(:index)
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
          assert_equal 1000, need.yearly_user_contacts
          assert_equal 10000, need.yearly_site_views
          assert_equal 1000, need.yearly_need_views
          assert_equal 2000, need.yearly_searches
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

        should "attempt to index the new need" do
          indexable_need = stub("indexable need")
          Search::IndexableNeed.expects(:new).with(is_a(Need)).returns(indexable_need)
          GovukNeedApi.indexer.expects(:index).with(indexable_need)

          post :create, @need_with_author
        end

        context "indexing fails" do
          setup do
            @exception = Search::Indexer::IndexingFailed.new(123456)
            GovukNeedApi.indexer.expects(:index).raises(@exception)
          end

          should "return a 201 status code" do
            post :create, @need_with_author
            assert_response :created
          end

          should "send out an exception report" do
            ExceptionNotifier::Notifier
              .expects(:background_exception_notification)
              .with(@exception)
            post :create, @need_with_author
          end
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
        GovukNeedApi.indexer.stubs(:index)

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

  context "PUT update" do
    setup do
      @need_instance = FactoryGirl.create(:need)
    end

    context "given a valid update" do
      setup do
        @updates = {
          id: @need_instance.need_id,
          role: "council tax payer",
          justifications: ["legislation"],
          yearly_user_contacts: 726
        }
        GovukNeedApi.indexer.stubs(:index)
      end

      context "given author details" do
        setup do
          @updates_with_author = @updates.merge author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          }
        end

        should "return a success response" do
          put :update, @updates_with_author
          assert_response 204
        end

        should "update the need" do
          put :update, @updates_with_author

          updated_need = Need.find(@need_instance.need_id)
          assert_equal "council tax payer", updated_need.role
          assert_equal ["legislation"], updated_need.justifications
          assert_equal 726, updated_need.yearly_user_contacts
        end

        should "leave existing values unchanged" do
          put :update, @updates_with_author

          updated_need = Need.find(@need_instance.need_id)
          [:goal, :benefit, :impact, :met_when].each do |field|
            assert_equal @need_instance.send(field), updated_need.send(field)
          end
        end

        should "attempt to index the new need" do
          indexable_need = stub("indexable need")
          Search::IndexableNeed.expects(:new).with(is_a(Need)).returns(indexable_need)
          GovukNeedApi.indexer.expects(:index).with(indexable_need)

          put :update, @updates_with_author
        end

        context "indexing fails" do
          setup do
            @exception = Search::Indexer::IndexingFailed.new(123456)
            GovukNeedApi.indexer.expects(:index).raises(@exception)
          end

          should "return a 204 status code" do
            put :update, @updates_with_author
            assert_response 204
          end

          should "send out an exception report" do
            ExceptionNotifier::Notifier
              .expects(:background_exception_notification)
              .with(@exception)
            put :update, @updates_with_author
          end
        end
      end

      context "when no author details are provided" do
        should "return a 422 status code" do
          put :update, @updates

          assert_equal 422, response.status
        end

        should "return an error in the json response" do
          put :update, @updates

          body = JSON.parse(response.body)
          assert_equal "author_not_provided", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal "Author details must be provided", body["errors"].first
        end

        should "not update the need" do
          Need.any_instance.expects(:save_as).never
          put :update, @updates
        end
      end
    end

    context "given an invalid update" do
      setup do
        @updates = {
          id: @need_instance.need_id,
          yearly_user_contacts: "lots"
        }
        GovukNeedApi.indexer.stubs(:index)
      end

      context "with author details" do
        setup do
          @updates_with_author = @updates.merge author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          }
        end

        should "return a 422 status" do
          put :update, @updates_with_author
          assert_response 422
        end

        should "return an error in the response" do
          put :update, @updates_with_author

          body = JSON.parse(response.body)
          assert_equal "invalid_attributes", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal(
            "Yearly user contacts is not a number",
            body["errors"].first
          )
        end

        should "not save the need" do
          Need.any_instance.expects(:save_as).never
          put :update, @updates_with_author
        end

        should "not attempt to index the need" do
          GovukNeedApi.indexer.expects(:index).never
          put :update, @updates_with_author
        end
      end

      should "return a 422 status" do
        put :update, @updates
        assert_response 422
      end

      should "return an error in the response" do
        put :update, @updates

        body = JSON.parse(response.body)
        assert_equal "author_not_provided", body["_response_info"]["status"]
      end

      should "not save the need" do
        Need.any_instance.expects(:save_as).never
        put :update, @updates
      end

      should "not attempt to index the need" do
        GovukNeedApi.indexer.expects(:index).never
        put :update, @updates
      end
    end

    context "attempting to update a closed need" do
      setup do
        @updates = {
          id: @need_instance.need_id,
          role: "council tax payer",
          author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          }
        }
      end

      should "return a 409" do
        Need.any_instance.expects(:closed?).returns(true)
        Need.any_instance.expects(:save_as).never
        put :update, @updates

        assert_response 409
      end
    end
  end

  context "PUT closed" do
    setup do
      @canonical_need = FactoryGirl.create(:need)
      @duplicate = FactoryGirl.create(:need)
    end

    context "given a valid update" do
      setup do
        @closed = {
          id: @duplicate.need_id,
          duplicate_of: @canonical_need.need_id
        }
        GovukNeedApi.indexer.stubs(:index)
      end

      context "given author details" do
        setup do
          @closed_with_author = @closed.merge author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          }
        end

        should "return a success response" do
          put :closed, @closed_with_author
          assert_response 204
        end

        should "marks the need as a duplicate of another need" do
          put :closed, @closed_with_author

          closed_need = Need.find(@duplicate.need_id)
          assert_equal @canonical_need.need_id, closed_need.duplicate_of
        end

        should "leave existing values unchanged" do
          put :closed, @closed_with_author

          closed_need = Need.find(@duplicate.need_id)
          [:goal, :benefit, :impact, :met_when].each do |field|
            assert_equal @duplicate.send(field), closed_need.send(field)
          end
        end

        should "not attempt to index the new need" do
          indexable_need = stub("indexable need")
          GovukNeedApi.indexer.expects(:index).never

          put :closed, @closed_with_author
        end
      end

      context "when no author details are provided" do
        should "return a 422 status code" do
          put :closed, @closed

          assert_equal 422, response.status
        end

        should "return an error in the json response" do
          put :closed, @closed

          body = JSON.parse(response.body)
          assert_equal "author_not_provided", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal "Author details must be provided", body["errors"].first
        end

        should "not update the need" do
          Need.any_instance.expects(:save_as).never
          put :closed, @closed
        end
      end
    end

    context "given an invalid update" do
      setup do
        @closed = {
          id: @duplicate.need_id,
        }
      end

      context "with author details" do
        setup do
          @closed_with_author = @closed.merge author: {
            name: "Winston Smith-Churchill",
            email: "winston@alphagov.co.uk"
          }
        end

        should "return a 422 status" do
          put :closed, @closed_with_author
          assert_response 422
        end

        should "return an error in the response" do
          put :closed, @closed_with_author

          body = JSON.parse(response.body)
          assert_equal "duplicate_of_not_provided", body["_response_info"]["status"]
          assert_equal 1, body["errors"].length
          assert_equal(
            "'Duplicate Of' id must be provided",
            body["errors"].first
          )
        end

        should "not save the need" do
          Need.any_instance.expects(:save_as).never
          put :closed, @closed_with_author
        end

        should "not attempt to index the need" do
          GovukNeedApi.indexer.expects(:index).never
          put :closed, @closed_with_author
        end
      end

      should "return a 422 status" do
        put :closed, @closed
        assert_response 422
      end

      should "return an error in the response" do
        put :closed, @closed

        body = JSON.parse(response.body)
        assert_equal "author_not_provided", body["_response_info"]["status"]
      end

      should "not save the need" do
        Need.any_instance.expects(:save_as).never
        put :closed, @closed
      end

      should "not attempt to index the need" do
        GovukNeedApi.indexer.expects(:index).never
        put :closed, @closed
      end
    end
  end

  context "DELETE reopen" do
    setup do
      @canonical = FactoryGirl.create(:need)
      @duplicate = FactoryGirl.create(:need)
      @closed = {
        id: @duplicate.need_id,
        duplicate_of: @canonical.need_id
      }
      @author = {
        author: {
          name: "Winston Smith-Churchill",
          email: "winston@alphagov.co.uk"
        }
      }
    end

    context "given a closed need" do
      setup do
        @closed_with_author = @closed.merge @author
        put :closed, @closed_with_author
      end

      should "return a success response" do
        delete :reopen, { id: @duplicate.need_id }.merge(@author)
        assert_response 204
      end

      should "not have duplicate_of set" do
        delete :reopen, { id: @duplicate.need_id }.merge(@author)
        reopened = Need.find(@duplicate.need_id)
        refute reopened.duplicate_of
      end

      should "return a 422 if no author details are present" do
        delete :reopen, { id: @duplicate.need_id }
        assert_response 422
      end

      should "contain an error message" do
        delete :reopen, { id: @duplicate.need_id }
        assert JSON.parse(response.body)["errors"]
      end

      should "return a 422 if reopen fails" do
        Need.any_instance.expects(:reopen).returns(false)
        delete :reopen, { id: @duplicate.need_id }.merge(@author)
        assert_response 422
      end
    end

    context "given an open need" do
      setup do
        delete :reopen, { id: @duplicate.need_id }.merge(@author)
      end

      should "not be able to reopen an open need" do
        assert_response 404
      end

      should "contain an error message" do
        assert JSON.parse(response.body)["error"]
      end
    end
  end
end
