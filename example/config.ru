#\ -s Mizuno -p 9297 -O request_log_file=stderr -E none
# The above is equivalent to 'rackup [options]'

# We don't assume SLF4J log output handler when launching via
# 'rackup', so you should do something like this here.
# If launching via bin/mizuno, this isn't required.
require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )

# FIXME: Currently Need Content-Length set to avoid double chunked
# transfer-encoding with rack 1.3 (not a problem in rack 1.2)!
use Rack::ContentLength

run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["Hello"]] }
