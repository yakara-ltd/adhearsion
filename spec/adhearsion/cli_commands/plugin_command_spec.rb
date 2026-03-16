# encoding: utf-8

require 'spec_helper'
require 'net/http'
require 'adhearsion/cli_commands'

describe Adhearsion::CLI::PluginCommand do
  subject { described_class.new }

  describe '#create_rubygem_hook' do
    context 'security: shell injection prevention' do
      before do
        # Stub get_rubygem_vals so it doesn't prompt
        allow(subject).to receive(:get_rubygem_vals)
      end

      it 'should not execute shell commands via backticks' do
        # If the implementation uses backticks/system/exec, a malicious
        # RUBYGEM_AUTH value could inject shell commands.
        # The fix should use Net::HTTP instead, which is not vulnerable.
        malicious_auth = "'; echo SHELL_INJECTION_DETECTED; '"
        malicious_name = "'; echo SHELL_INJECTION_DETECTED; '"

        ENV['RUBYGEM_AUTH'] = malicious_auth
        ENV['RUBYGEM_NAME'] = malicious_name

        # The method should use Net::HTTP, not shell execution.
        # We verify by checking that Kernel#` is never called.
        expect(subject).not_to receive(:`)

        # Stub Net::HTTP to prevent actual network calls
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        response_double = instance_double(Net::HTTPResponse, body: '{"ok": true}')
        allow(http_double).to receive(:request).and_return(response_double)

        subject.create_rubygem_hook
      ensure
        ENV.delete('RUBYGEM_AUTH')
        ENV.delete('RUBYGEM_NAME')
      end
    end
  end

  describe '#generate_github_webhook' do
    before do
      allow(subject).to receive(:get_github_vals)
      ENV['GITHUB_USERNAME'] = 'testuser'
      ENV['GITHUB_PASSWORD'] = 'testpass'
      ENV['GITHUB_REPO'] = 'owner/repo'
    end

    after do
      ENV.delete('GITHUB_USERNAME')
      ENV.delete('GITHUB_PASSWORD')
      ENV.delete('GITHUB_REPO')
    end

    it 'should use HTTPS for the webhook callback URL' do
      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start).and_yield(http_double)
      response_double = instance_double(Net::HTTPResponse, body: '{}')
      allow(http_double).to receive(:request).and_return(response_double)

      # Capture the request body to verify the webhook URL
      expect(http_double).to receive(:request) do |req|
        body = JSON.parse(req.body)
        expect(body['config']['url']).to start_with('https://')
        response_double
      end

      subject.create_github_hook
    end
  end
end
