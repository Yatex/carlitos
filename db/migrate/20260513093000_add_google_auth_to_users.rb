class AddGoogleAuthToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :google_connected_at, :datetime
    add_column :users, :google_email_verified, :boolean, null: false, default: false

    add_index :users, :google_uid, unique: true
  end
end
