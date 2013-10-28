require_relative '../../test_helper'

class NeedRevisionPresenterTest < ActiveSupport::TestCase

  class MockRevision < OpenStruct
    def changes_with(previous)
      { role: [ "user", "home owner" ] }
    end
  end

  setup do
    @revision = MockRevision.new(
      action_type: "update",
      snapshot: {
        role: "home owner"
      },
      author: {
        name: "Winston Smith-Churchill",
        email: "winston@alphagov.co.uk",
        uid: "w1n5t0n"
      },
      created_at: Time.parse("2013-01-01")
    )
    @previous_revision = MockRevision.new(
      snapshot: {
        role: "user"
      }
    )
  end

  should "return the basic attributes" do
    response = NeedRevisionPresenter.new(@revision, @previous_revision).present

    assert_equal "update", response[:action_type]

    assert_equal "Winston Smith-Churchill", response[:author][:name]
    assert_equal "winston@alphagov.co.uk", response[:author][:email]
    assert_equal "w1n5t0n", response[:author][:uid]

    assert_equal Time.parse("2013-01-01"), response[:created_at]

    assert_equal ["user", "home owner"], response[:changes][:role]
  end
end
