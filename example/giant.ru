# -*- ruby -*-
#\ -s Fishwife -p 9297 -E production

require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )

class GiantGenerator
  FILLER = <<-END
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
    eiusmod tempor incididunt ut labore et dolore magna aliqua.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
    eiusmod tempor incididunt ut labore et dolore magna aliqua.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
    eiusmod tempor incididunt ut labore et dolore magna aliqua.
  END

  def each
    loop { yield FILLER[0..rand( FILLER.size)] }
  end
end

class App
  def call( env )
    [ 200, { 'Content-Type' => 'text/plain' }, GiantGenerator.new ]
  end
end

run App.new
