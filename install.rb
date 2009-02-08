require File.join(File.dirname(__FILE__), 'rails', 'init' )

Scrooge::Base.setup!

puts IO.read(File.join(File.dirname(__FILE__), 'README.textile'))