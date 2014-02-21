require_relative '../test_helper'

class NoteTest < ActiveSupport::TestCase
  setup do
    @need = FactoryGirl.create(:need)
    @atts = {
      text: "test",
      need_id: @need.need_id,
      author: {
        name: "Winston Smith-Churchill",
        email: "winston@alphagov.co.uk",
        uid: "win5t0n"
      }
    }
  end

  should "be able to create a note" do
    Need.expects(:find).returns(@need)

    note = Note.new(@atts)
    note.save
    note.reload

    assert_equal "test", note.text
    assert_equal "Winston Smith-Churchill", note.author["name"]
    assert_equal @need.revisions.first.id.to_s, note.revision
  end
end
