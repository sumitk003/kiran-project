class CreateEmailSuppressions < ActiveRecord::Migration[7.0]
  def change
    create_table :email_suppressions do |t|
      t.string :email, null: false
      t.bigint :contact_id
      t.bigint :agent_id
      t.bigint :account_id
      t.datetime :unsubscribed_at, null: false

      t.timestamps
    end

    add_index :email_suppressions, :email
    add_index :email_suppressions, :contact_id
    add_index :email_suppressions, :agent_id
    add_index :email_suppressions, :account_id
    add_index :email_suppressions, [:email, :account_id], unique: true
  end
end
