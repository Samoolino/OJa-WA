# Compatibility implementation for extension migrations generated against the
# spree_extension gem's legacy Migration API.
#
# SpreeExtension::Migration[version] delegates to Rails' versioned migration
# class so existing extension migrations remain executable on Rails 7.1.
module SpreeExtension
  class Migration
    def self.[](version)
      ActiveRecord::Migration[version]
    end
  end
end
