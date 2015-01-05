require_relative '../integration_test_helper'

class SearchingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    use_test_index
  end

  teardown do
    delete_test_index
  end

  should "return no results on an empty index" do
    get "/needs?q=user"
    body = JSON.parse(last_response.body)
    assert_equal 0, body["results"].count
  end

  should "return a result that matches on a text field" do
    post_json "/needs", {
       role: "student",
       goal: "apply for student finance",
       benefit: "I can get the money I need to go to university",
       author: { name: "Bob", email: "bob@example.com" },
       applies_to_all_organisations: true,
    }.to_json

    assert_equal 201, last_response.status

    refresh_index

    get "/needs?q=student"
    body = JSON.parse(last_response.body)
    assert_equal 1, body["results"].count
    assert_equal "apply for student finance", body["results"].first["goal"]
    assert_equal true, body["results"].first["applies_to_all_organisations"]
    assert_equal NeedStatus::PROPOSED, body["results"].first["status"]["description"]
  end

  should "match a result with a similar word" do
    post_json "/needs", {
       role: "student",
       goal: "apply for student finance",
       benefit: "I can get the money I need to go to university",
       author: { name: "Bob", email: "bob@example.com" }
    }.to_json

    assert_equal 201, last_response.status

    refresh_index

    get "/needs?q=students"
    body = JSON.parse(last_response.body)
    assert_equal 1, body["results"].count
    assert_equal "apply for student finance", body["results"].first["goal"]
  end

  should "match a result on the need ID" do
    post_json "/needs", {
       role: "student",
       goal: "apply for student finance",
       benefit: "I can get the money I need to go to university",
       author: { name: "Bob", email: "bob@example.com" }
    }.to_json

    assert_equal 201, last_response.status
    submitted_need = JSON.parse(last_response.body)

    refresh_index

    get "/needs?q=#{submitted_need["id"]}"

    body = JSON.parse(last_response.body)
    assert_equal 1, body["results"].count
    assert_equal "apply for student finance", body["results"].first["goal"]
  end

  should "paginate the matching needs correctly" do
    52.times do |n|
      post_json "/needs", {
         role: "monkey #{n}",
         goal: "apply for monkey finance",
         benefit: "I can get the money I need to go to monkeyversity",
         author: { name: "Bob", email: "bob@example.com" },
         applies_to_all_organisations: true,
      }.to_json

      assert_equal 201, last_response.status, last_response.body
    end

    # Elasticsearch needs a little time to index the search results in the background
    sleep 3

    get "/needs?q=monkeys"

    assert_equal 200, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal 50, body["results"].size
    assert_equal 52, body["total"]

    assert last_response.headers.has_key?("Link")
    link_header = LinkHeader.parse(last_response.headers["Link"])
    assert_equal "http://example.org/needs?page=2&q=monkeys", link_header.find_link(["rel", "next"]).href

    get "/needs?q=monkeys&page=2"
    assert_equal 200, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal 2, body["results"].size
  end
end
