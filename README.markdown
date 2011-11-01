# Ruby Multicast SAP Listener

Ruby script that listens to the Session Announcement Protocol (SAP) multicast group, parses the binary SDP header and text body, and displays the received datagram.

Requires the 'BinData' Ruby gem for declarative parsing of the binary data.

	$ gem install bindata
	$ chmod +x sap_listener.rb
	$ ./sap_listener.rb
