class CreateWalletAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_wallet_accounts do |t|
      t.integer :user_id
      t.integer :vendor_id
      t.string :account_code
      t.integer :account_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.integer :balance_cents, default: 0, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :spree_wallet_accounts, :user_id
    add_index :spree_wallet_accounts, :vendor_id
    add_index :spree_wallet_accounts, :account_code, unique: true
  end
end
