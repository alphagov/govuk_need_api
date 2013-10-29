require_relative '../../test_helper'

class NeedPresenterTest < ActiveSupport::TestCase

  def stub_presenter(presenter, attributes, presenter_output)
    presenter_stub = stub(:present => presenter_output)

    attributes = [attributes] unless attributes.is_a?(Array)
    matchers = attributes.map {|a| has_entries(a) }

    presenter.constantize.expects(:new)
                            .with(*matchers)
                            .returns(presenter_stub)
  end

  setup do
    @need = OpenStruct.new(
      id: "blah-bson-id",
      need_id: 123456,
      role: "business owner",
      goal: "find out the VAT rate",
      benefit: "I can charge my customers the correct amount",
      organisation_ids: [ "ministry-of-testing" ],
      organisations: [
        { id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing" }
      ],
      justifications: [ "legislation", "other" ],
      impact: "Noticed by an expert audience",
      met_when: [ "the user sees the current vat rate" ],
      monthly_user_contacts: 1000,
      monthly_site_views: 10000,
      monthly_need_views: 1000,
      monthly_searches: 2000,
      currently_met: false,
      other_evidence: "Other evidence",
      legislation: "link#1\nlink#2",
      revisions_with_changes: [
        [{ author: "Author 1" }, { author: "Author 0" }],
        [{ author: "Author 2" }, { author: "Author 1" }],
        [{ author: "Author 3" }, { author: "Author 2" }],
        [{ author: "Author 4" }, { author: "Author 3" }],
        [{ author: "Author 5" }, { author: "Author 4" }],
        [{ author: "Author 6" }, { author: "Author 5" }],
      ]
    )
    @presenter = NeedPresenter.new(@need)

    stub_presenter("OrganisationPresenter", @need.organisations.first, "presented organisation")

    stub_presenter("NeedRevisionPresenter", @need.revisions_with_changes[0], "Revision 1")
    stub_presenter("NeedRevisionPresenter", @need.revisions_with_changes[1], "Revision 2")
    stub_presenter("NeedRevisionPresenter", @need.revisions_with_changes[2], "Revision 3")
    stub_presenter("NeedRevisionPresenter", @need.revisions_with_changes[3], "Revision 4")
    stub_presenter("NeedRevisionPresenter", @need.revisions_with_changes[4], "Revision 5")
  end

  should "return an need as json" do
    response = @presenter.as_json

    assert_equal "ok", response[:_response_info][:status]
    assert_equal 123456, response[:id]

    assert_equal "business owner", response[:role]
    assert_equal "find out the VAT rate", response[:goal]
    assert_equal "I can charge my customers the correct amount", response[:benefit]

    assert_equal ["ministry-of-testing"], response[:organisation_ids]

    assert_equal [ "presented organisation" ], response[:organisations]

    assert_equal ["legislation", "other"], response[:justifications]
    assert_equal "Noticed by an expert audience", response[:impact]
    assert_equal ["the user sees the current vat rate"], response[:met_when]

    assert_equal 1000, response[:monthly_user_contacts]
    assert_equal 10000, response[:monthly_site_views]
    assert_equal 1000, response[:monthly_need_views]
    assert_equal 2000, response[:monthly_searches]
    assert_equal false, response[:currently_met]
    assert_equal "Other evidence", response[:other_evidence]
    assert_equal "link#1\nlink#2", response[:legislation]

    assert_equal [ "Revision 1", "Revision 2", "Revision 3", "Revision 4", "Revision 5" ], response[:revisions]
  end

  should "return a custom status" do
    response = @presenter.as_json(status: "created")

    assert_equal "created", response[:_response_info][:status]
  end
end
