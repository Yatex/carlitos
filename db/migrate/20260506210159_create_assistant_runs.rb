class CreateAssistantRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :assistant_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.text :input, null: false
      t.text :output
      t.string :status, null: false, default: "pending"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :assistant_runs, [:user_id, :created_at]
    add_index :assistant_runs, :metadata, using: :gin
  end
end
