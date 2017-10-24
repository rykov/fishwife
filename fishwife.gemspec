# -*- ruby -*- encoding: utf-8 -*-

gem 'rjack-tarpit', '~> 2.1'
require 'rjack-tarpit/spec'

RJack::TarPit.specify do |s|
  require 'fishwife/base'

  s.version = Fishwife::VERSION
  s.summary = "A Jetty based Rack HTTP 1.1 server."

  s.add_developer( 'David Kellum', 'dek-oss@gravitext.com' )

  s.depend 'rack',                  '>= 1.6.4', '< 2.1'
  s.depend 'rjack-jetty',           '>= 9.2.11', '< 9.5'
  s.depend 'rjack-slf4j',           '~> 1.7.2'

  s.depend 'json',                  '~> 2.1',       :dev
  s.depend 'rjack-logback',         '~> 1.5',       :dev
  s.depend 'rspec',                 '~> 3.6.0',     :dev

  s.maven_strategy = :no_assembly
end
