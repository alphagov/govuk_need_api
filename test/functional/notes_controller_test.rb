require_relative '../test_helper'

class NotesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @need = create(:need)
    @note = {
      text: "test",
      need_id: @need.need_id,
      author: {
        name: stub_user.name,
        email: stub_user.email
      }
    }
  end

  context "POST create" do
    should "save the note" do
      post :create, @note

      note = Note.first

      assert_equal 201, response.status
      assert_equal "test", note.text
      assert_equal @need.need_id, note.need_id
      assert_equal stub_user.name, note.author["name"]
      assert_equal stub_user.email, note.author["email"]
    end

    should "show errors if a note is not valid" do
      post :create, @note.except(:text)

      body = JSON.parse(response.body)
      assert_equal 422, response.status
      assert_equal "invalid_attributes", body["_response_info"]["status"]
    end
  end
end
