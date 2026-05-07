class MemoryNotesController < ApplicationController
  before_action :authenticate_user!

  def index
    @memory_notes = current_user.memory_notes.recent
  end

  def new
    @memory_note = current_user.memory_notes.new(source: "web")
  end

  def create
    @memory_note = current_user.memory_notes.new(memory_note_params.merge(source: "web"))

    if @memory_note.save
      redirect_back fallback_location: memory_notes_path, notice: "Nota guardada en tu memoria."
    else
      redirect_back fallback_location: dashboard_path, alert: @memory_note.errors.full_messages.to_sentence
    end
  end

  private

  def memory_note_params
    params.require(:memory_note).permit(:title, :content)
  end
end
