class AddFreeTrialTrackingToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :free_trial_started_at, :datetime
    add_column :users, :free_trial_ends_at, :datetime

    execute <<~SQL.squish
      UPDATE users
      SET free_trial_started_at = created_at,
          free_trial_ends_at = created_at + INTERVAL '14 days',
          plan_expires_at = COALESCE(plan_expires_at, created_at + INTERVAL '14 days'),
          subscription_status = CASE
            WHEN created_at + INTERVAL '14 days' > CURRENT_TIMESTAMP THEN 'trialing'
            ELSE 'canceled'
          END
      WHERE current_plan = 'free'
        AND free_trial_started_at IS NULL
    SQL

    add_index :users, :free_trial_ends_at
  end

  def down
    remove_index :users, :free_trial_ends_at
    remove_column :users, :free_trial_ends_at
    remove_column :users, :free_trial_started_at
  end
end
