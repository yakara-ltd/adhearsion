# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk::Call caller ID security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/call.rb', __dir__)) }

  it 'should sanitize callerid values in the dial method' do
    # The dial method sets :callerid from dial_command.from without
    # sanitization. Newlines, backticks, and Asterisk variable syntax
    # like ${...} in the from field could inject AMI parameters.
    # The callerid assignment must use sanitization.
    dial_section = source[/def dial\(.*?^        end/m]
    callerid_lines = dial_section.lines.select { |l| l =~ /:callerid/ }

    callerid_lines.each do |line|
      expect(line).to match(/sanitize/),
        "callerid set without sanitization: #{line.strip}"
    end
  end
end
