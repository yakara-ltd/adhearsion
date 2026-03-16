# encoding: utf-8

Then /^I should see the usage message$/ do
  expect(all_output).to include("ahn create")
  expect(all_output).to include("ahn start")
  expect(all_output).to include("ahn version")
  expect(all_output).to include("ahn plugin")
  expect(all_output).to include("ahn help")
end

Then /^I should see the plugin usage message$/ do
  expect(all_output).to include("ahn plugin create_ahnhub_hooks")
  expect(all_output).to include("ahn plugin create_github_hook")
  expect(all_output).to include("ahn plugin create_rubygem_hook")
end

When /^I wait (\d+) seconds?$/ do |arg1|
  sleep arg1.to_i
end

Given /^that I create a valid app under "([^"]*)"$/ do |path|
  run_command_and_stop("ahn create #{path}", fail_on_error: false)
  expect(exist?(path)).to be true

  remove "#{path}/Gemfile"
end

Then /^there should be a valid adhearsion directory named "([^"]*)"$/ do |path|
  expect(exist?(path)).to be true

  cd(path)
  expect(exist?('lib')).to be true
  expect(exist?('config')).to be true
  expect(exist?('Gemfile')).to be true
  expect(exist?('README.md')).to be true
  expect(exist?('Rakefile')).to be true
  expect(exist?('config/adhearsion.rb')).to be true
  expect(exist?('config/environment.rb')).to be true

  ## NOTE: Aruba's cd method is not really changing directories
  ## Either we use cd or we need absolute path... could not figure out cleaner
  ## way to get back to previous dir.
  dotsback=1.upto(path.split(File::SEPARATOR)[0..-1].count).collect {|x| ".."}.join(File::SEPARATOR)
  dotsback.shift if dotsback[0].is_a?(String) and dotsback[0].empty?
  cd(dotsback)
end
