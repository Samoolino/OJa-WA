# Spree 4.7 no longer guarantees that the legacy extension migration helper
# is loaded before application migrations are evaluated. OJa-WA retains
# historical migrations generated against SpreeExtension::Migration, so load
# the compatibility helper during application boot before Rails enumerates
# the migration set.
require 'spree_extension/migration'
