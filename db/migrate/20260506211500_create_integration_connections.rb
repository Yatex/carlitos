class CreateIntegrationConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :integration_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :status, null: false, default: "disconnected"
      t.string :display_name
      t.string :external_id
      t.datetime :connected_at
      t.datetime :last_synced_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :integration_connections, [:user_id, :provider], unique: true
    add_index :integration_connections, :metadata, using: :gin
  end
end
