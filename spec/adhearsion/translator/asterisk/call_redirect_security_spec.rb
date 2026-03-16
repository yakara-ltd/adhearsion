# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk::Call redirect target security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/call.rb', __dir__)) }

  it 'should sanitize redirect targets before passing to AGI Transfer' do
    # The Redirect command passes command.to directly to EXEC Transfer
    # without validation. Asterisk interprets special characters like
    # &, @, and newlines in Transfer targets, which can be abused
    # to manipulate call routing. The target must be sanitized.
    #
    # Look for sanitization near the Transfer AGI command
    transfer_lines = source.lines.each_with_index.select do |line, _idx|
      line =~ /EXEC Transfer/
    end

    transfer_lines.each do |line, idx|
      # Check that the line wraps command.to in a sanitization method
      expect(line).to match(/sanitize/),
        "call.rb:#{idx + 1}: Redirect target passed unsanitized to EXEC Transfer"
    end
  end
end
