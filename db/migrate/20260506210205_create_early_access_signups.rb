class CreateEarlyAccessSignups < ActiveRecord::Migration[7.1]
  def change
    create_table :early_access_signups do |t|
      t.string :name
      t.string :email, null: false

      t.timestamps
    end
    add_index :early_access_signups, :email, unique: true
  end
end
