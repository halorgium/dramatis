#!/usr/bin/env ruby

$:.push File.join( File.dirname(__FILE__), "..", "..", "..", "lib" )

require 'chat'

password = "xyzzy"
group = "general"

screen = Chat::Screen::Fox.new

server = Chat::Server.new password

joe = Chat::Client.new screen, server, password, group, "joe"
jane = Chat::Client.new screen, server, password, group, "jane"
jim = Chat::Client.new screen, server, password, group, "jim"
sue = Chat::Client.new screen, server, password, group, "sue"

