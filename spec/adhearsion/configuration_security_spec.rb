# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe Adhearsion::Configuration do
  describe '.warn_if_default_credentials!' do
    let(:logger) { double('logger') }

    before do
      Adhearsion.config = nil
      allow(Adhearsion::Logging).to receive(:get_logger).and_return(logger)
      allow(logger).to receive(:trace)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
    end

    it 'should warn when username and password are defaults' do
      config = Adhearsion::Configuration.new
      expect(config.core.username).to eq("usera@127.0.0.1")
      expect(config.core.password).to eq("1")

      expect(logger).to receive(:warn).with(/default credentials/i)
      Adhearsion::Configuration.warn_if_default_credentials!(config)
    end

    it 'should not warn when credentials have been customized' do
      config = Adhearsion::Configuration.new do
        username "real_user@pbx.example.com"
        password "s3cureP@ss!"
      end

      expect(logger).not_to receive(:warn)
      Adhearsion::Configuration.warn_if_default_credentials!(config)
    end
  end
end
