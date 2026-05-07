class CreateAssistantMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :assistant_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :direction, null: false
      t.string :channel, null: false
      t.text :body, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :assistant_messages, [:user_id, :created_at]
    add_index :assistant_messages, :metadata, using: :gin
  end
end
