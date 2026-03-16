# encoding: utf-8

require 'spec_helper'

describe 'Plugin thread safety' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/plugin.rb', __dir__)) }

  it 'should synchronize access to @@rake_tasks' do
    # Class variables shared across threads must be synchronized.
    # The tasks method appends to @@rake_tasks which is shared state.
    expect(source).to match(/@@rake_tasks_mutex/),
      "@@rake_tasks should be protected by a mutex for thread-safe access."
  end
end
