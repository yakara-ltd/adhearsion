# encoding: utf-8

require 'spec_helper'

describe 'method_missing proxy security' do
  # Files that use method_missing to proxy calls should use public_send
  # instead of send, to prevent calling private/protected methods on
  # the target object.
  files_to_check = {
    'CallController' => 'lib/adhearsion/call_controller.rb',
    'MenuBuilder' => 'lib/adhearsion/call_controller/input/menu_builder.rb',
    'Calls' => 'lib/adhearsion/calls.rb',
    'Console' => 'lib/adhearsion/console.rb',
    'Events' => 'lib/adhearsion/events.rb',
    'ThreadSafeArray' => 'lib/adhearsion/foundation/thread_safety.rb',
    'Configuration' => 'lib/adhearsion/configuration.rb',
  }

  files_to_check.each do |name, path|
    describe name do
      let(:source) { File.read(File.expand_path("../../#{path}", __dir__)) }

      it 'should use public_send instead of send in method_missing or [] accessor' do
        # Find method_missing blocks that use .send (not public_send, __send__)
        # Pattern: lines with .send that are inside method_missing-like proxies
        lines = source.lines.each_with_index.select do |line, _idx|
          line =~ /\.send\b/ && line !~ /public_send|__send__|register_handler/
        end
        expect(lines.map { |line, idx| "#{path}:#{idx + 1}: #{line.strip}" }).to be_empty,
          "Found .send calls that should use .public_send:\n" +
          lines.map { |line, idx| "  #{path}:#{idx + 1}: #{line.strip}" }.join("\n")
      end
    end
  end
end
