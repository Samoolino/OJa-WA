source 'https://rubygems.org'

# Spree 4.7 core/backend/emails are the supported runtime family.
# The legacy frontend and Devise adapter are maintained on their respective
# branches and are validated by their compatibility constraints below.
gem 'spree', github: 'spree/spree', ref: 'e9d1c48223ff4d7185e979314db131ccf83b6359'
gem 'spree_emails', github: 'spree/spree', ref: 'e9d1c48223ff4d7185e979314db131ccf83b6359'
gem 'spree_backend', github: 'spree/spree_backend', ref: 'b3fd22e87eefbffc869215f97273cceb99171290'
gem 'spree_frontend', github: 'spree/spree_legacy_frontend', ref: '13c9c81023b55f4d6ada0b699746260c45c2d1e9'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', ref: 'b4a99d75d5e19c4cec5c571b1945fe44c930f939'

gem 'rails-controller-testing'
gem 'redis', '~> 5.0'
# Rails 7.1 ActiveSupport RedisCacheStore expects the 2.x ConnectionPool API.
gem 'connection_pool', '~> 2.5'
# PostgreSQL is the CI/test database adapter used by the dummy application.
gem 'pg', '~> 1.5'

gemspec
