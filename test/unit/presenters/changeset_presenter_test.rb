require_relative '../../test_helper'

class ChangesetPresenterTest < ActiveSupport::TestCase

  setup do
    current = OpenStruct.new(
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

    note = OpenStruct.new(
      text: "test",
      author: {
        name: "Sir John Anderson",
        email: "jock@alphagov.co.uk",
        uid: "j0hn"
      },
      created_at: Time.parse("2013-01-02")
    )

    @changeset = OpenStruct.new(
      current: current,
      changes: { role: [ "user", "home owner" ] },
      notes: [note]
    )
  end

  should "return the basic attributes" do
    response = ChangesetPresenter.new(@changeset).as_json

    assert_equal "update", response[:action_type]

    assert_equal "Winston Smith-Churchill", response[:author][:name]
    assert_equal "winston@alphagov.co.uk", response[:author][:email]
    assert_equal "w1n5t0n", response[:author][:uid]

    assert_equal Time.parse("2013-01-01"), response[:created_at]

    assert_equal ["user", "home owner"], response[:changes][:role]
  end

  should "return notes as part of the changset" do
    response = ChangesetPresenter.new(@changeset).as_json

    note = response[:notes][0]
    assert_equal "test", note[:text]
    assert_equal "Sir John Anderson", note[:author][:name]
    assert_equal "jock@alphagov.co.uk", note[:author][:email]
    assert_equal "j0hn", note[:author][:uid]
    assert_equal Time.parse("2013-01-02"), note[:created_at]
  end
end
