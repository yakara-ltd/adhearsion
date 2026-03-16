# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe Adhearsion::Configuration do
  describe '.warn_if_no_tls!' do
    let(:logger) { double('logger') }

    before do
      Adhearsion.config = nil
      allow(Adhearsion::Logging).to receive(:get_logger).and_return(logger)
      allow(logger).to receive(:trace)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
    end

    it 'should warn when certs_directory is nil' do
      config = Adhearsion::Configuration.new
      expect(config.core.certs_directory).to be_nil

      expect(logger).to receive(:warn).with(/TLS.*not configured|no TLS|unencrypted/i)
      Adhearsion::Configuration.warn_if_no_tls!(config)
    end

    it 'should not warn when certs_directory is configured' do
      config = Adhearsion::Configuration.new do
        certs_directory "/etc/adhearsion/certs"
      end

      expect(logger).not_to receive(:warn)
      Adhearsion::Configuration.warn_if_no_tls!(config)
    end
  end
end
