class CreateMemoryListItems < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_list_items do |t|
      t.references :memory_list, null: false, foreign_key: true
      t.string :content, null: false
      t.datetime :completed_at

      t.timestamps
    end
    add_index :memory_list_items, [:memory_list_id, :completed_at]
  end
end
