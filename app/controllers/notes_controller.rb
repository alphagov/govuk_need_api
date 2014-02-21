class NotesController < ApplicationController
  def create
    note = Note.new(filtered_params)
    if note.save
      render nothing: true, status: 201
    else
      error 422, message: "Something went wrong"
    end
  end

  private

  def filtered_params
    params.except(:action, :controller)
  end
end
