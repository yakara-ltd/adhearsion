# encoding: utf-8

$testing = true

if ENV.key?("CI")
  require "simplecov"
  require "simplecov-lcov"
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'coverage/lcov.info'
  SimpleCov.start
end

require 'logger'  # Required for Ruby 3.3+ compatibility

%w{
  bundler/setup
  active_support
  stringio
  countdownlatch
  timecop
  adhearsion
}.each { |f| require f }

Thread.abort_on_exception = true

Bundler.require(:default, :test) if defined?(Bundler)

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color = true

  config.mock_with :rspec do |mocks|
    mocks.add_stub_and_should_receive_to Celluloid::Proxy::Abstract
  end

  config.raise_errors_for_deprecations!

  config.before :suite do
    Adhearsion::Logging.start :trace, Adhearsion.config.core.logging.formatter
    Adhearsion.config.core.after_hangup_lifetime = 10
    Celluloid.shutdown_timeout = 1
    Adhearsion::Initializer.new.initialize_exception_logger
  end

  config.before :each do
    Adhearsion.config.core.i18n.locale_path = ["#{File.dirname(__FILE__)}/fixtures/locale"]
    Adhearsion::Initializer.new.setup_i18n_load_path

    Adhearsion.router = nil
    @uuid = SecureRandom.uuid
    allow(Adhearsion).to receive(:new_request_id).and_return @uuid
  end

  config.after :each do
    Timecop.return
    Adhearsion::Events.clear
    if defined?(Celluloid)
      # Terminate call actors without full Celluloid shutdown/boot cycle
      # (shutdown/boot recreates threads per test which is very slow)
      begin
        calls = Adhearsion.instance_variable_get(:@active_calls)
        if calls
          calls.values.each do |call|
            call.terminate if call.alive?
          rescue Celluloid::DeadActorError, NoMethodError
          end
        end
      rescue => e
        # Ignore cleanup errors
      end
      Adhearsion.active_calls = nil

      # Clean up supervised actors (e.g. :statistics) from the registry
      begin
        if Celluloid::Actor[:statistics]
          Celluloid::Actor[:statistics].terminate
        end
      rescue Celluloid::DeadActorError, NoMethodError
      end

      # If the supervision tree is corrupted, do a full reboot
      services_alive = begin; Celluloid.services; rescue; nil; end
      unless services_alive
        Celluloid.shutdown
        Celluloid.boot
      end
    end
  end
end

Adhearsion::Events.exception do |e, _|
  warn "#{e.inspect}\n  #{(e.backtrace || ['NO BACKTRACE']).join("\n  ")}"
end

# Test modules for #mixin methods
module TestBiscuit
  def throwadogabone
    true
  end
end

module MarmaladeIsBetterThanJam
  def sobittersweet
    true
  end
end

def new_uuid
  SecureRandom.uuid
end
alias :random_call_id :new_uuid
