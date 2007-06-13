= Net::RAOP::Client

  http://raop.rubyforge.org/

== DESCRIPTION

Net::RAOP::Client is an Airport Express client.  It allows you to stream
music to an Airport Express.

== EXAMPLES

  raop = Net::RAOP::Client.new('192.168.1.173')
  raop.connect
  raop.play $stdin
  raop.disconnect

== TODO

* Add support for decoding OGG, M4P, MP3

== AUTHORS

Copyright (c) 2007 by Aaron Patterson (aaronp@rubyforge.org) 

== ACKNOWLEDGMENTS

Most of this code was based on JustePort[http://nanocrew.net/software/justeport/], so Thank You for JustePort!

== LICENSE

This library is distributed under the GPL.  Please see the LICENSE[link://files/LICENSE_txt.html] file.

