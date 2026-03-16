# encoding: utf-8

# Load ActiveSupport with proper initialization for 7.1+
require 'active_support'
require 'active_support/version'
if ActiveSupport::VERSION::MAJOR >= 7 && ActiveSupport::VERSION::MINOR >= 1
  require 'active_support/deprecation'
  # ActiveSupport 7.1+ already has a deprecator, no need to set it
end

require 'active_support/json'

module Adhearsion
  module CLI
    class PluginCommand < Thor

      namespace :plugin

      desc "create_github_hook", "Creates ahnhub hook to track github commits"
      def create_github_hook
        get_github_vals
        generate_github_webhook
      end

      desc "create_rubygem_hook", "Creates ahnhub hook to track rubygem updates"
      def create_rubygem_hook
        get_rubygem_vals

        require 'net/http'

        uri = URI("https://rubygems.org/api/v1/web_hooks/fire")
        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = ENV['RUBYGEM_AUTH']
        req.set_form_data(
          'gem_name' => ENV['RUBYGEM_NAME'],
          'url'      => 'https://www.ahnhub.com/gem'
        )

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          response = http.request(req)
          puts response.body
        end
      end

      desc "create_ahnhub_hooks", "Creates ahnhub hooks for both a rubygem and github repo"
      def create_ahnhub_hooks
        create_github_hook
        create_rubygem_hook
      end

      protected

      def get_rubygem_vals
        ENV['RUBYGEM_NAME'] ||= ask "What's the rubygem name?"
        ENV['RUBYGEM_AUTH'] ||= ask_secret "What's your authorization key for Rubygems?"
      end

      def get_github_vals
        ENV['GITHUB_USERNAME'] ||= ask "What's your github username?"
        ENV['GITHUB_TOKEN']    ||= ask_secret "What's your GitHub personal access token?"
        ENV['GITHUB_REPO']     ||= ask "Please enter the owner and repo (for example, 'adhearsion/new-plugin'): "
      end

      def ask_secret(prompt)
        require 'io/console'
        $stdout.print "#{prompt} "
        $stdin.noecho(&:gets).chomp
      ensure
        $stdout.puts
      end

      def github_repo_owner
        ENV['GITHUB_REPO'].split('/')[0]
      end

      def github_repo_name
        ENV['GITHUB_REPO'].split('/')[1]
      end

      def generate_github_webhook
        require 'net/http'

        uri = URI("https://api.github.com/repos/#{github_repo_owner}/#{github_repo_name}/hooks")
        req = Net::HTTP::Post.new(uri.to_s)

        req["Authorization"] = "token #{ENV['GITHUB_TOKEN']}"
        req.body = {
          name:   "web",
          active: true,
          events: ["push", "pull_request"],
          config: {url: "https://ahnhub.com/github"}
        }.to_json

        req["content-type"] = "application/json"
        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
          response = http.request(req)
          puts response.body
        end
      end
    end
  end
end
