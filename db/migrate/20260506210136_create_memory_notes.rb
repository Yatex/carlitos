class CreateMemoryNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_notes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :source, null: false, default: "web"

      t.timestamps
    end
    add_index :memory_notes, [:user_id, :created_at]
  end
end
