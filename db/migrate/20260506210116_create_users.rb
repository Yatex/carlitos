class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :timezone, null: false, default: "America/Montevideo"
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :subscription_status, null: false, default: "free"
      t.string :current_plan, null: false, default: "free"

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
