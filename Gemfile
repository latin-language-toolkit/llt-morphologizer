source 'https://rubygems.org'

# Specify your gem's dependencies in llt-morphologizer.gemspec
gemspec
gem 'coveralls', require: false

gem 'llt-core', git: 'git://github.com/latin-language-toolkit/llt-core.git'
gem 'llt-core_extensions', git: 'git://github.com/latin-language-toolkit/llt-core_extensions.git'
gem 'llt-constants', git: 'git://github.com/latin-language-toolkit/llt-constants.git'
gem 'llt-db_handler', git: 'git://github.com/latin-language-toolkit/llt-db_handler.git'
gem 'llt-db_handler-stub', git: 'git://github.com/latin-language-toolkit/llt-db_handler-stub.git'
gem 'llt-form_builder', git: 'git://github.com/latin-language-toolkit/llt-form_builder.git'
gem 'llt-helpers', git: 'git://github.com/latin-language-toolkit/llt-helpers.git'
gem 'llt-logger', git: 'git://github.com/latin-language-toolkit/llt-logger.git'

platform :ruby do
  gem 'pg'
end

platform :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'jruby-httpclient'
end
