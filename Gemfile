source 'https://rubygems.org'

gemspec

gem 'sinatra', require: nil
gem 'rack', '~> 3.2.1'
gem 'reel', github: "logicsys/reel", branch: "develop"
gem 'reel-rack', github: "logicsys/reel-rack", branch: "develop"
gem 'ruby_ami', github: "logicsys/ruby_ami", branch: "develop"
gem 'baby_squeel', github: "logicsys/baby_squeel", branch: "develop"
gem 'blather', github: "logicsys/blather", branch: "develop"
gem 'celluloid', github: "logicsys/celluloid", branch: "develop"
gem 'celluloid-io', github: "logicsys/celluloid-io", branch: "develop"


group :test do
  # TODO: some expectations started failing in 3.8.3
  # The be_a_kind_of matcher requires that the actual object responds to either
  # #kind_of? or #is_a? methods  but it responds to neigher of two methods.
  gem 'rspec-expectations', '~> 3.13.5'
end
