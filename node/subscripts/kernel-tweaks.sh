#/bin/bash

sed -i /etc/sysctl.conf
    -e 's/^\(kernel.sem *=\).*$/\1 250  32000 32  4096/'
    -e 's/^\(net.ipv4.ip_local_port_range *=\).*$/\1 15000 35530/' #Append the following line to the same file. This increases the ephemeral port range to accommodate application proxies
    -e 's/^\(net.netfilter.nf_conntrack_max *=\).*/\1 1048576/' #Append the following line to the same file. This increases the connection-tracking table size:
#Run the following command to reload the sysctl.conf file and activate the new settings:
sysctl -p /etc/sysctl.conf
