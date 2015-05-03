# -*- ruby -*-
#\ -s Fishwife -O connections=tcp://127.0.0.1:9292|ssl://0.0.0.0:9433?key_store_path=spec/data/localhost.keystore&key_store_password=password

# We don't assume SLF4J log output handler when launching via
# 'rackup', so you should do something like this here.
# If launching via bin/fishwife, this isn't required.
require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )

run proc { [ 200, {"Content-Type" => "text/plain"}, ["Hello", " world!\n"] ] }
