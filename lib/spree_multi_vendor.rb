require 'spree_core'
# Spree Backend 4.7 expects the core runtime preference base to be loaded
# before its backend runtime configuration is evaluated.
require 'spree/core/preferences/runtime_configuration'
require 'spree_backend'
require 'spree_emails'
require 'spree_multi_vendor/engine'
require 'spree_multi_vendor/version'
require 'spree_extension'
require 'deface'

module SpreeMultiVendor
  # TODO: this should be moved into preferences
  def self.vendorized_models
    SpreeMultiVendor::Config[:vendorized_models].map(&:classify).map do |class_name|
      "::Spree::#{class_name}".safe_constantize
    end.compact.uniq
  end
end
