ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Rails 6.0 + concurrent-ruby >= 1.3.5 + Ruby < 3.1: concurrent-ruby dropped a
# transitive `require 'logger'`, so ActiveSupport's LoggerThreadSafeLevel hits an
# uninitialized `Logger` constant at boot. Require it explicitly first.
require 'logger'

require 'bundler/setup' # Set up gems listed in the Gemfile.
