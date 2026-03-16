# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe Adhearsion::Configuration do
  describe '.enforce_security!' do
    let(:logger) { double('logger') }

    before do
      Adhearsion.config = nil
      allow(Adhearsion::Logging).to receive(:get_logger).and_return(logger)
      allow(logger).to receive(:trace)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
    end

    context 'in production environment' do
      it 'should raise an error when using default credentials' do
        config = Adhearsion::Configuration.new(:production)
        expect {
          Adhearsion::Configuration.enforce_security!(config)
        }.to raise_error(Adhearsion::Configuration::ConfigurationError, /default credentials/i)
      end

      it 'should not raise when credentials have been customized' do
        config = Adhearsion::Configuration.new(:production) do
          username "real_user@pbx.example.com"
          password "s3cureP@ss!"
        end
        expect {
          Adhearsion::Configuration.enforce_security!(config)
        }.not_to raise_error
      end
    end

    context 'in development environment' do
      it 'should only warn when using default credentials, not raise' do
        config = Adhearsion::Configuration.new(:development)
        expect(logger).to receive(:warn).with(/default credentials/i)
        expect {
          Adhearsion::Configuration.enforce_security!(config)
        }.not_to raise_error
      end
    end
  end
end
