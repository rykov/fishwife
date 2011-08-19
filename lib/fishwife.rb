#
# A Rack handler for Jetty 7.
#
# Written by Don Werve <don@madwombat.com>
#

# Java integration for talking to Jetty.
require 'java'

# Logging interface
require 'rjack-slf4j'

# Load Jetty JARs.
require 'rjack-jetty'

require 'rack'
require 'fishwife/rack_servlet'
require 'fishwife/http_server'
require 'rack/handler/fishwife'
