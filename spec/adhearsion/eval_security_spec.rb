# encoding: utf-8

require 'spec_helper'

describe 'eval usage security' do
  describe 'MenuBuilder' do
    let(:source) { File.read(File.expand_path('../../lib/adhearsion/call_controller/input/menu_builder.rb', __dir__)) }

    it 'should not use eval to extract block binding context' do
      eval_calls = source.scan(/\beval\s+["']self["']/)
      expect(eval_calls).to be_empty,
        "Found unsafe eval usage to extract block context. Use block.binding.receiver instead."
    end
  end

  describe 'CallController' do
    let(:source) { File.read(File.expand_path('../../lib/adhearsion/call_controller.rb', __dir__)) }

    it 'should not use eval to extract block binding context' do
      eval_calls = source.scan(/\beval\s+["']self["']/)
      expect(eval_calls).to be_empty,
        "Found unsafe eval usage to extract block context. Use block.binding.receiver instead."
    end
  end
end
