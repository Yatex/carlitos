class MemoryListItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memory_list

  def create
    item = @memory_list.memory_list_items.new(memory_list_item_params)

    if item.save
      redirect_back fallback_location: memory_list_path(@memory_list), notice: "Ítem agregado."
    else
      redirect_back fallback_location: memory_list_path(@memory_list), alert: item.errors.full_messages.to_sentence
    end
  end

  def update
    item = @memory_list.memory_list_items.find(params[:id])
    completed_at = ActiveModel::Type::Boolean.new.cast(params.dig(:memory_list_item, :completed)) ? Time.current : nil
    item.update!(completed_at:)
    redirect_back fallback_location: memory_list_path(@memory_list), notice: "Lista actualizada."
  end

  private

  def set_memory_list
    @memory_list = current_user.memory_lists.find(params[:memory_list_id])
  end

  def memory_list_item_params
    params.require(:memory_list_item).permit(:content)
  end
end
