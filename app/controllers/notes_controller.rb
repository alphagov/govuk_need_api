class NotesController < ApplicationController
  def create
    note = Note.new(filtered_params)
    if note.save
      head :created
    else
      error 422, message: :invalid_attributes, errors: note.errors.full_messages
    end
  end

  private

  def filtered_params
    params.permit(
      :text,
      :need_id,
      author: [
        :name,
        :email,
      ],
    )
  end
end
