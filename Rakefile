require 'bundler'
Bundler::GemHelper.install_tasks

# Directly load Spree generator support files
begin
  require 'spree/testing_support/extension_rake'
  
  desc 'Generates a dummy app for testing'
  task :test_app do
    ENV['LIB_NAME'] = 'spree_multi_vendor'
    Rake::Task['extension:test_app'].invoke
  end
rescue LoadError
  # Fallback if testing hooks are isolated
end