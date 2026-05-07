class AddAdminRolesAndPlanGrantsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :plan_expires_at, :datetime
    add_column :users, :plan_granted_at, :datetime
    add_reference :users, :plan_granted_by, foreign_key: { to_table: :users }

    add_index :users, :role
    add_index :users, :plan_expires_at
  end
end
