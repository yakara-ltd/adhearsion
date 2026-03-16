# encoding: utf-8

require 'spec_helper'

describe 'Nokogiri XML parsing security' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/rayo/component/input.rb', __dir__)) }

  it 'should use NONET flag to prevent external entity loading' do
    parse_lines = source.lines.select { |l| l =~ /Nokogiri::XML\.parse/ }
    expect(parse_lines).not_to be_empty, "No Nokogiri::XML.parse calls found"

    parse_lines.each do |line|
      expect(line).to match(/NONET/),
        "Nokogiri::XML.parse should include NONET flag to prevent network access during parsing:\n  #{line.strip}"
    end
  end
end
