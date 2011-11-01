#!/usr/bin/env ruby

require 'socket'
require 'ipaddr'
require 'bindata'

# constants
SAP_MULTICAST_ADDR = "239.255.255.255"
SAP_MULTICAST_PORT = 9875

#
# SAP Header and Packet Format
#
#  0                   1                   2                   3
#  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# | V=1 |A|R|T|E|C|   auth len    |         msg id hash           |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                                                               |
# :                originating source (32 or 128 bits)            :
# :                                                               :
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                    optional authentication data               |
# :                              ....                             :
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
# |                      optional payload type                    |
# +                                         +-+- - - - - - - - - -+
# |                                         |0|                   |
# + - - - - - - - - - - - - - - - - - - - - +-+                   |
# |                                                               |
# :                            payload                            :
# |                                                               |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#

class SapPacket < BinData::Record
   endian  :big

   bit3    :version
   bit1    :addressType
   bit1    :reserved
   bit1    :messageType
   bit1    :encryption
   bit1    :compressed
   uint8   :authLen
   uint16  :msgIdHash
   uint32  :originatingSource
   string  :authData, :read_length => :authLen
   stringz :payloadType
   count_bytes_remaining :bytes_remaining
   string  :payload, :read_length => :bytes_remaining
end

@sapThread = Thread::new do
   begin
      puts 'Starting the SAP thread'
      
      ipAddr =  IPAddr.new(SAP_MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
      sock = UDPSocket.new
      sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ipAddr)
      sock.bind(Socket::INADDR_ANY, SAP_MULTICAST_PORT)
      
      loop do
         msg, info = sock.recvfrom(4096)
         puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
         
         sapPacket = SapPacket.read(msg);
         
         puts "SAP Packet: #{sapPacket.version} #{sapPacket.authData}"
         puts "Inspection: #{sapPacket}"
      end
   ensure
      puts 'Cleaningup the SAP thread'
      sock.close
   end
end

@sapThread.join