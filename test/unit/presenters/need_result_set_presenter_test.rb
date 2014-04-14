require_relative '../../test_helper'

class NeedResultSetPresenterTest < ActiveSupport::TestCase

  # this class imitates the behaviour of the Need class when it
  # is scoped, with the ability to iterate over the needs whilst
  # providing additional attribute accessors
  class MockPaginatedNeeds < OpenStruct
    include Enumerable

    def each(&block)
      needs.each(&block)
    end
  end

  setup do
    needs = [
      OpenStruct.new(
        id: "blah-bson-id-one",
        need_id: 1,
        role: "business owner",
        goal: "find out the VAT rate",
        benefit: "I can charge my customers the correct amount",
        organisation_ids: [ "ministry-of-testing" ],
        organisations: [
          OpenStruct.new(id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing")
        ]
      ),
      OpenStruct.new(
        id: "blah-bson-id-two",
        need_id: 2,
        role: "car owner",
        goal: "renew my car tax",
        benefit: "I can drive my car for another year",
        organisation_ids: [ "ministry-of-testing" ],
        organisations: [
          OpenStruct.new(id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing")
        ]
      )
    ]

    @needs = MockPaginatedNeeds.new(
      needs: needs,
      first_page?: false,
      last_page?: false,
      current_page: 1,
      offset_value: 0,
      total_pages: 1,
    )

    @view_context = stub
    @view_context.stubs(:needs_url).returns("http://need-api.dev.gov.uk/needs")
  end

  should "return a collection of needs as json" do
    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal "ok", response[:_response_info][:status]
    assert_equal 2, response[:results].size

    assert_equal [1, 2], response[:results].map {|i| i[:id] }
    assert_equal ["business owner", "car owner"], response[:results].map {|i| i[:role] }
    assert_equal ["find out the VAT rate", "renew my car tax"], response[:results].map {|i| i[:goal] }
    assert_equal ["I can charge my customers the correct amount", "I can drive my car for another year"], response[:results].map {|i| i[:benefit] }

    assert_equal ["ministry-of-testing"], response[:results][0][:organisation_ids]

    assert_equal 1, response[:results][0][:organisations].size
    assert_equal "Ministry of Testing", response[:results][0][:organisations][0][:name]
    assert_equal "ministry-of-testing", response[:results][0][:organisations][0][:id]
  end

  context "including pagination links in output" do
    should "return links to the next and previous pages when paginated" do
      @needs.current_page = 2

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 1))
                      .returns("url to page 1")

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 2))
                      .returns("url to page 2")

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 3))
                      .returns("url to page 3")

      response = NeedResultSetPresenter.new(@needs, @view_context).as_json
      links = response[:_response_info][:links]

      assert_equal 3, links.size

      assert_equal "url to page 1", links[0]["href"]
      assert_equal "previous", links[0]["rel"]

      assert_equal "url to page 3", links[1]["href"]
      assert_equal "next", links[1]["rel"]

      assert_equal "url to page 2", links[2]["href"]
      assert_equal "self", links[2]["rel"]
    end

    should "not return links to the previous page when on the first page" do
      @needs.current_page = 1
      @needs.expects(:first_page?).returns(true)

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 1))
                      .returns("url to page 1")

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 2))
                      .returns("url to page 2")

      response = NeedResultSetPresenter.new(@needs, @view_context).as_json
      links = response[:_response_info][:links]

      assert_equal 2, links.size

      assert_equal "url to page 2", links[0]["href"]
      assert_equal "next", links[0]["rel"]

      assert_equal "url to page 1", links[1]["href"]
      assert_equal "self", links[1]["rel"]
    end

    should "not return links to the next page when on the last page" do
      @needs.current_page = 3
      @needs.expects(:last_page?).returns(true)

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 2))
                      .returns("url to page 2")

      @view_context.expects(:needs_url)
                      .with(has_entry(:page, 3))
                      .returns("url to page 3")

      response = NeedResultSetPresenter.new(@needs, @view_context).as_json
      links = response[:_response_info][:links]

      assert_equal 2, links.size

      assert_equal "url to page 2", links[0]["href"]
      assert_equal "previous", links[0]["rel"]

      assert_equal "url to page 3", links[1]["href"]
      assert_equal "self", links[1]["rel"]
    end
  end

  context "returning pagination link data" do
    setup do
      @view_context.stubs(:needs_url)
                      .with(has_entry(:page, 1))
                      .returns("url to page 1")
      @view_context.stubs(:needs_url)
                      .with(has_entry(:page, 2))
                      .returns("url to page 2")
      @view_context.stubs(:needs_url)
                      .with(has_entry(:page, 3))
                      .returns("url to page 3")
    end

    should "return links to the next and previous pages when paginated" do
      @needs.current_page = 2

      links = NeedResultSetPresenter.new(@needs, @view_context).links

      assert_equal 3, links.size
      assert links.all? {|l| l.is_a?(LinkHeader::Link) }

      assert_equal "url to page 1", links[0].href
      assert_equal "previous", links[0].attrs["rel"]

      assert_equal "url to page 3", links[1].href
      assert_equal "next", links[1].attrs["rel"]

      assert_equal "url to page 2", links[2].href
      assert_equal "self", links[2].attrs["rel"]
    end

    should "include given scope params in the links" do
      @needs.current_page = 2

      @view_context.expects(:needs_url)
                      .with(:page => 1, :foo => "bar")
                      .returns("scoped url to page 1")
      @view_context.expects(:needs_url)
                      .with(:page => 2, :foo => "bar")
                      .returns("scoped url to page 2")
      @view_context.expects(:needs_url)
                      .with(:page => 3, :foo => "bar")
                      .returns("scoped url to page 3")

      links = NeedResultSetPresenter.new(@needs, @view_context, :scope_params => {:foo => "bar"}).links

      assert_equal 3, links.size
      assert links.all? {|l| l.is_a?(LinkHeader::Link) }

      assert_equal "scoped url to page 1", links[0].href
      assert_equal "previous", links[0].attrs["rel"]

      assert_equal "scoped url to page 3", links[1].href
      assert_equal "next", links[1].attrs["rel"]

      assert_equal "scoped url to page 2", links[2].href
      assert_equal "self", links[2].attrs["rel"]
    end

    should "not return links to the previous page when on the first page" do
      @needs.current_page = 1
      @needs.stubs(:first_page?).returns(true)

      links = NeedResultSetPresenter.new(@needs, @view_context).links

      assert_equal 2, links.size
      assert links.all? {|l| l.is_a?(LinkHeader::Link) }

      assert_equal "url to page 2", links[0].href
      assert_equal "next", links[0].attrs["rel"]

      assert_equal "url to page 1", links[1].href
      assert_equal "self", links[1].attrs["rel"]
    end

    should "not return links to the next page when on the last page" do
      @needs.current_page = 3
      @needs.stubs(:last_page?).returns(true)

      links = NeedResultSetPresenter.new(@needs, @view_context).links

      assert_equal 2, links.size
      assert links.all? {|l| l.is_a?(LinkHeader::Link) }

      assert_equal "url to page 2", links[0].href
      assert_equal "previous", links[0].attrs["rel"]

      assert_equal "url to page 3", links[1].href
      assert_equal "self", links[1].attrs["rel"]
    end

  end

  should "include the total number of needs" do
    @needs.expects(:count).returns(50)

    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal 50, response[:total]
  end

  should "include the start index" do
    @needs.stubs(:offset_value).returns(20)

    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal 21, response[:start_index]
  end

  should "include the current page" do
    @needs.stubs(:current_page).returns(5)

    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal 5, response[:current_page]
  end

  should "include the number of pages" do
    @needs.stubs(:total_pages).returns(123)

    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal 123, response[:pages]
  end

  should "include the size of the current page" do
    response = NeedResultSetPresenter.new(@needs, @view_context).as_json

    assert_equal 2, response[:page_size]
  end
end
