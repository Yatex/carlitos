class CreateDailyBriefings < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_briefings do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.boolean :enabled, null: false, default: false
      t.time :delivery_time, null: false, default: "08:00"
      t.string :timezone, null: false, default: "America/Montevideo"

      t.timestamps
    end
    add_index :daily_briefings, :user_id, unique: true
  end
end
