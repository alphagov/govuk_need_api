class NotesController < ApplicationController
  def create
    note = Note.new(filtered_params)
    if note.save
      head :created
    else
      error 422, message: "Something went wrong"
    end
  end

  private

  def filtered_params
    params.except(:action, :controller)
  end
end
