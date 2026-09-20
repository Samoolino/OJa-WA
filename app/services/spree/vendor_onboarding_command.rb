module Spree
  class VendorOnboardingCommand
    COMMANDS = %w[create_store connect_payment_account activate_store].freeze

    def self.call(vendor:, actor:, command_type:, idempotency_key:, correlation_id:, request_id:, params: {})
      new(vendor:, actor:, command_type:, idempotency_key:, correlation_id:, request_id:, params:).call
    end

    def initialize(vendor:, actor:, command_type:, idempotency_key:, correlation_id:, request_id:, params:)
      @vendor = vendor
      @actor = actor
      @command_type = command_type.to_s
      @idempotency_key = idempotency_key.to_s
      @correlation_id = correlation_id.to_s
      @request_id = request_id.to_s
      @params = params.to_h.stringify_keys
    end

    def call
      validate_identity!
      validate_request!

      existing = Spree::VendorCommandRecord.find_by(vendor_id: @vendor.id, idempotency_key: @idempotency_key)
      return existing.response_payload.merge("replayed" => true) if existing

      ActiveRecord::Base.transaction do
        resource = execute_command!
        payload = serialize(resource)

        Spree::VendorCommandRecord.create!(
          vendor: @vendor,
          vendor_store: resource.is_a?(Spree::VendorStore) ? resource : resource.vendor_store,
          command_type: @command_type,
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          request_id: @request_id,
          resource_version: resource.respond_to?(:lock_version) ? resource.lock_version : nil,
          response_payload: payload
        )
        payload.merge("replayed" => false)
      end
    end

    private

    def validate_identity!
      return if @vendor.users.exists?(id: @actor.id)

      raise ActiveRecord::RecordNotFound, "Vendor access denied"
    end

    def validate_request!
      raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
      raise ArgumentError, "correlation_id is required" if @correlation_id.blank?
      raise ArgumentError, "request_id is required" if @request_id.blank?
      raise ArgumentError, "command_type is invalid" unless COMMANDS.include?(@command_type)
    end

    def execute_command!
      case @command_type
      when "create_store" then create_store!
      when "connect_payment_account" then connect_payment_account!
      when "activate_store" then activate_store!
      end
    end

    def create_store!
      Spree::VendorStore.create!(
        vendor: @vendor,
        name: @params.fetch("name"),
        external_reference: @params["external_reference"],
        address: @params["address"],
        latitude: @params["latitude"],
        longitude: @params["longitude"],
        policy: @params.fetch("policy", {})
      )
    end

    def connect_payment_account!
      store = @vendor.vendor_stores.find(@params["vendor_store_id"]) if @params["vendor_store_id"].present?

      Spree::VendorPaymentAccount.create!(
        vendor: @vendor,
        vendor_store: store,
        provider: @params.fetch("provider"),
        external_account_id: @params.fetch("external_account_id"),
        status: @params.fetch("status", "pending"),
        capabilities: @params.fetch("capabilities", {}),
        metadata: @params.fetch("metadata", {})
      )
    end

    def activate_store!
      store = @vendor.vendor_stores.lock.find(@params.fetch("vendor_store_id"))
      raise ArgumentError, "payment account required" unless store.vendor_payment_accounts.exists?
      raise ArgumentError, "store policy or geo coordinates required" if store.policy.blank? && !store.geo_configured?

      store.update!(state: "active")
      store
    end

    def serialize(resource)
      if resource.is_a?(Spree::VendorStore)
        {
          "vendor_store_id" => resource.id,
          "vendor_id" => @vendor.id,
          "name" => resource.name,
          "state" => resource.state,
          "version" => resource.lock_version,
          "correlation_id" => @correlation_id
        }
      else
        {
          "vendor_payment_account_id" => resource.id,
          "vendor_id" => @vendor.id,
          "vendor_store_id" => resource.vendor_store_id,
          "provider" => resource.provider,
          "status" => resource.status,
          "settlement_ready" => resource.settlement_ready?,
          "correlation_id" => @correlation_id
        }
      end
    end
  end
end
