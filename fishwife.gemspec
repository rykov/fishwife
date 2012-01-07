# -*- ruby -*- encoding: utf-8 -*-

gem 'rjack-tarpit', '~> 2.0.a'
require 'rjack-tarpit/spec'

$LOAD_PATH.unshift( File.join( File.dirname( __FILE__ ), 'lib' ) )

require 'fishwife/base'

RJack::TarPit.specify do |s|

  s.version  = Fishwife::VERSION
  s.summary = "A hard working Jetty 7 based rack handler."

  s.add_developer( 'David Kellum', 'dek-oss@gravitext.com' )

  s.depend 'rack',                  '~> 1.3.2'
  s.depend 'rjack-jetty',           '~> 7.5.0'
  s.depend 'rjack-slf4j',           '~> 1.6.1'

  s.depend 'rjack-logback',         '~> 1.2',       :dev
  s.depend 'rspec',                 '~> 2.6.0',     :dev

  s.platform = :java

end
