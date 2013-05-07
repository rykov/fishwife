# -*- ruby -*-
#\ -s Fishwife -p 9297

# We don't assume SLF4J log output handler when launching via
# 'rackup', so you should do something like this here.
# If launching via bin/fishwife, this isn't required.
require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )

run proc { [ 200, {"Content-Type" => "text/plain"}, ["Hello", " world!\n"] ] }
