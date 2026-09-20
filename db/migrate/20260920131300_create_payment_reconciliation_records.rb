class CreatePaymentReconciliationRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_payment_reconciliation_records do |t|
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :payment_reference
      t.string :order_reference
      t.string :status, null: false, default: "UNMATCHED"
      t.string :expected_currency
      t.bigint :expected_amount_minor
      t.string :observed_currency
      t.bigint :observed_amount_minor
      t.string :correlation_id, null: false
      t.string :resolution_operation_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :spree_payment_reconciliation_records,
              [:provider, :provider_event_id],
              unique: true,
              name: "idx_payment_reconciliation_provider_event"
    add_index :spree_payment_reconciliation_records, :payment_reference
    add_index :spree_payment_reconciliation_records, :order_reference
    add_index :spree_payment_reconciliation_records, :correlation_id
    add_check_constraint :spree_payment_reconciliation_records,
                         "status IN ('MATCHED','UNMATCHED','MISSING','DUPLICATE','AMOUNT_MISMATCH','CURRENCY_MISMATCH','TIMING_DIFFERENCE')",
                         name: "payment_reconciliation_status_check"
    add_check_constraint :spree_payment_reconciliation_records,
                         "expected_amount_minor IS NULL OR expected_amount_minor >= 0",
                         name: "payment_reconciliation_expected_amount_nonnegative"
    add_check_constraint :spree_payment_reconciliation_records,
                         "observed_amount_minor IS NULL OR observed_amount_minor >= 0",
                         name: "payment_reconciliation_observed_amount_nonnegative"
  end
end
