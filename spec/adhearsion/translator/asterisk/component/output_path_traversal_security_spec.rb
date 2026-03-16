# encoding: utf-8

require 'spec_helper'

describe 'Output component path traversal security' do
  let(:source) { File.read(File.expand_path('../../../../../lib/adhearsion/translator/asterisk/component/output.rb', __dir__)) }

  it 'should validate audio paths against directory traversal' do
    # The path_for_audio_node method strips file:// and constructs a
    # file path from SSML audio src attributes. Without validation,
    # an attacker can use "../" sequences to access files outside the
    # intended audio directory (e.g., <audio src="file://../../etc/passwd"/>).
    #
    # The method must reject or sanitize traversal sequences.
    expect(source).to match(/\.\..*raise|\.\..*reject|\.\..*invalid|path_traversal|sanitize.*path|reject.*\.\./i),
      "path_for_audio_node does not appear to validate against directory traversal (../ sequences)"
  end
end
