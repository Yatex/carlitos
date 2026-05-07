class MemoryListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memory_list, only: [:show]

  def index
    @memory_lists = current_user.memory_lists.recent.includes(:memory_list_items)
  end

  def show
    @memory_list_item = @memory_list.memory_list_items.new
  end

  def new
    @memory_list = current_user.memory_lists.new
  end

  def create
    @memory_list = current_user.memory_lists.new(memory_list_params)

    if @memory_list.save
      redirect_back fallback_location: memory_lists_path, notice: "Lista creada."
    else
      redirect_back fallback_location: dashboard_path, alert: @memory_list.errors.full_messages.to_sentence
    end
  end

  private

  def set_memory_list
    @memory_list = current_user.memory_lists.find(params[:id])
  end

  def memory_list_params
    params.require(:memory_list).permit(:title)
  end
end
