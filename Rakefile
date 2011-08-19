# -*- ruby -*-

$LOAD_PATH << './lib'

require 'rubygems'
gem     'rjack-tarpit', '~> 1.3.2'
require 'rjack-tarpit'

require 'fishwife/base'

t = RJack::TarPit.new( 'fishwife', Fishwife::VERSION )

t.specify do |h|
  h.developer( 'Don Werve', 'don@madwombat.com' )
  h.developer( 'David Kellum', 'dek-oss@gravitext.com' )

  h.extra_deps     += [ [ 'rack',          '~> 1.3.1' ],
                        [ 'rjack-jetty',   '~> 7.4.3' ] ]
  h.extra_dev_deps += [ [ 'rjack-logback', '~> 1.2.0' ],
                        [ 'rspec',         '~> 2.6.0' ] ]
end

# Version/date consistency checks:

task :check_history_version do
  t.test_line_match( 'History.rdoc', /^==/, / #{ t.version } / )
end
task :check_history_date do
  t.test_line_match( 'History.rdoc', /^==/, /\([0-9\-]+\)$/ )
end

task :gem  => [ :check_history_version  ]
task :tag  => [ :check_history_version, :check_history_date ]
task :push => [ :check_history_version, :check_history_date ]

t.define_tasks
