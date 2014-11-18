#!/usr/bin/ruby

# This script can be used to add and delete routes from the system's routing
# table in response to allocate/deallocate events in the DHCP server.
#
# To use it, add the following to a `subnet6` stanza in which you're using
# `prefix6`:
#
#    on commit {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "add",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-pd),
#              client-address,
#              "eth0");
#    }
#    on release {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "del",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-prefix),
#              "eth0");
#    }
#    on expiry {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "del",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-prefix),
#              "eth0");
#    }
#
# Adjust `"eth0"` to be whatever interface the routes need to be added to in
# your configuration.
#

require 'ipaddr'

ACTION = ARGV[0]
IADATA = ARGV[1].split(':').map { |o| o.length == 1 ? "0#{o}" : o }

if ACTION == "add"
	client_address = ARGV[2]
	dev = ARGV[3]

	net = "#{IADATA[25..-1].join.scan(/..../).join(':')}/#{IADATA[24].to_i(16)}"
	system("ip route add #{net} via #{client_address} dev #{dev}")
elsif ACTION == "del"
	net = "#{IPAddr.new(IADATA[9..-1].join.scan(/..../).join(':')).to_s}/#{IADATA[8].to_i(16)}"

	route = `ip -6 ro sh`.split("\n").grep /#{net}/
	system("ip route del #{route[0]}")
end
