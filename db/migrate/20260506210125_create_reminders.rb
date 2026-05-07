class CreateReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.datetime :remind_at
      t.string :recurrence_rule
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
    add_index :reminders, [:user_id, :remind_at]
    add_index :reminders, [:user_id, :status]
  end
end
