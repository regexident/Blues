begin
  gem 'overcommit'
rescue Gem::LoadError
  system 'gem install overcommit'
end

system 'overcommit --install'
system 'overcommit --sign'
