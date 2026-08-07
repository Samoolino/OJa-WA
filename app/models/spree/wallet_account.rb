module Spree
  class WalletAccount < Spree::Base
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    validates :account_code, presence: true, uniqueness: true
    validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }

    before_validation :generate_code, on: :create

    enum account_type: { customer: 0, vendor: 1, plan_owner: 2 }
    enum status: { inactive: 0, active: 1, suspended: 2 }

    def generate_code
      self.account_code ||= SecureRandom.hex(6).upcase
    end

    def transfer_to!(target_account, amount_cents)
      raise ArgumentError, 'amount must be positive' if amount_cents <= 0
      raise ArgumentError, 'source account inactive' unless active?
      raise ArgumentError, 'target account inactive' unless target_account.active?
      raise ArgumentError, 'target account must be a vendor wallet' unless target_account.vendor?
      raise ArgumentError, 'insufficient balance' if balance_cents < amount_cents

      ActiveRecord::Base.transaction do
        update!(balance_cents: balance_cents - amount_cents)
        target_account.update!(balance_cents: target_account.balance_cents + amount_cents)

        Spree::AllocationAudit.create!(user: user,
                                       vendor: target_account.vendor,
                                       action: 'transfer_to_vendor',
                                       amount_cents: amount_cents,
                                       status: :success,
                                       metadata: { from_account: account_code, to_account: target_account.account_code })
      end
    end
  end
end
