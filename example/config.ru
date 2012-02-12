#\ -s Fishwife -p 9297 -O request_log_file=stderr -E none
# The above is equivalent to 'rackup [options]'

# We don't assume SLF4J log output handler when launching via
# 'rackup', so you should do something like this here.
# If launching via bin/fishwife, this isn't required.
require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )

use Rack::ContentLength

run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["Hello"]] }
