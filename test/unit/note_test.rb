require_relative '../test_helper'

class NoteTest < ActiveSupport::TestCase
  setup do
    @need = create(:need)
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
    Need.expects(:where).twice.returns([@need])

    note = Note.new(@atts)
    note.save
    note.reload

    assert_equal "test", note.text
    assert_equal "Winston Smith-Churchill", note.author["name"]
    assert_equal @need.revisions.first.id.to_s, note.revision
  end

  should "not save a note without a need_id" do
    note = Note.new(@atts.except(:need_id))

    refute note.save
    assert note.errors.has_key?(:need_id)
  end

  should "not save a note without a valid need_id" do
    note = Note.new(@atts.merge(need_id: :foo))

    refute note.save
    assert note.errors.has_key?(:need_id)
  end

  should "not save a note without text" do
    note = Note.new(@atts.except(:text))

    refute note.save
    assert note.errors.has_key?(:text)
  end

  should "not save a note without an author" do
    note = Note.new(@atts.except(:author))

    refute note.save
    assert note.errors.has_key?(:author)
  end
end
