class CreateMemoryLists < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end
    add_index :memory_lists, [:user_id, :title]
  end
end
