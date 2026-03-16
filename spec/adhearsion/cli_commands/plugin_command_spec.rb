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
        malicious_auth = "'; echo SHELL_INJECTION_DETECTED; '"
        malicious_name = "'; echo SHELL_INJECTION_DETECTED; '"

        ENV['RUBYGEM_AUTH'] = malicious_auth
        ENV['RUBYGEM_NAME'] = malicious_name

        expect(subject).not_to receive(:`)

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
      ENV['GITHUB_TOKEN'] = 'ghp_testtoken123'
      ENV['GITHUB_REPO'] = 'owner/repo'
    end

    after do
      ENV.delete('GITHUB_USERNAME')
      ENV.delete('GITHUB_TOKEN')
      ENV.delete('GITHUB_REPO')
    end

    it 'should use HTTPS for the webhook callback URL' do
      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start).and_yield(http_double)
      response_double = instance_double(Net::HTTPResponse, body: '{}')
      allow(http_double).to receive(:request).and_return(response_double)

      expect(http_double).to receive(:request) do |req|
        body = JSON.parse(req.body)
        expect(body['config']['url']).to start_with('https://')
        response_double
      end

      subject.create_github_hook
    end

    it 'should use token-based auth, not basic auth with password' do
      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start).and_yield(http_double)
      response_double = instance_double(Net::HTTPResponse, body: '{}')
      allow(http_double).to receive(:request).and_return(response_double)

      expect(http_double).to receive(:request) do |req|
        # Should use Authorization header with token, not basic auth
        expect(req['Authorization']).to match(/^(token |Bearer )/)
        response_double
      end

      subject.create_github_hook
    end
  end

  describe 'credential input' do
    let(:source) { File.read(File.expand_path('../../../lib/adhearsion/cli_commands/plugin_command.rb', __dir__)) }

    it 'should use ask_secret for sensitive values, not plain ask' do
      # Secrets should use ask_secret (which masks input), not plain ask
      # Look for lines that prompt for passwords/auth/tokens using plain ask
      sensitive_patterns = /\bask\s+["'].*(?:password|auth|token|secret)/i
      insecure_lines = source.lines.select { |l| l.match?(sensitive_patterns) }
      expect(insecure_lines).to be_empty,
        "Sensitive prompts should use ask_secret for masked input, found:\n" +
        insecure_lines.map(&:strip).join("\n")
    end
  end
end
