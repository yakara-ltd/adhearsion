# encoding: utf-8

JRUBY_OPTS_SAVED=ENV['JRUBY_OPTS']
JAVA_OPTS_SAVED=ENV['JAVA_OPTS']

require 'cucumber'
require 'aruba/cucumber'
require 'adhearsion'

Aruba.configure do |config|
  config.exit_timeout = ENV.has_key?('ARUBA_TIMEOUT') ? ENV['ARUBA_TIMEOUT'].to_i : (RUBY_PLATFORM == 'java' ? 60 : 30)
end

Before do
  ENV['AHN_CORE_RECONNECT_ATTEMPTS'] = '0'
  ENV['AHN_CORE_PORT'] = '1'
end

Before '@reconnect' do
  ENV['AHN_CORE_RECONNECT_ATTEMPTS'] = '100'
end

# Aruba upstream overwrites these variables so set them here until it is fixed.
if RUBY_PLATFORM == 'java'
  Before do
    set_environment_variable('JRUBY_OPTS', "#{ENV['JRUBY_OPTS']} #{JRUBY_OPTS_SAVED}")
    set_environment_variable('JAVA_OPTS', "#{ENV['JAVA_OPTS']} #{JAVA_OPTS_SAVED}")
  end
end

# Profile slowest features
# @see https://itshouldbeuseful.wordpress.com/2010/11/10/find-your-slowest-running-cucumber-features/
scenario_times = {}
Around() do |scenario, block|
  start = Time.now
  block.call
  scenario_times["#{scenario.location.file}::#{scenario.name}"] = Time.now - start
end
at_exit do
  max_scenarios = scenario_times.size > 30 ? 30 : scenario_times.size
  puts "------------- Top #{max_scenarios} slowest scenarios -------------"
  sorted_times = scenario_times.sort { |a, b| b[1] <=> a[1] }
  sorted_times[0..max_scenarios - 1].each do |key, value|
    puts "#{value.round(2)}  #{key}"
  end
end
