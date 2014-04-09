#/bin/bash
readonly SYSCTL_CONF_FILE='/etc/sysctl.conf'

sed -i "${SYSCTL_CONF_FILE}" \
    -e 's/^\(kernel.sem *=\).*$/\1 250  32000 32  4096/' \
    -e 's/^\(net.ipv4.ip_local_port_range *=\).*$/\1 15000 35530/' \
    -e 's/^\(net.netfilter.nf_conntrack_max *=\).*/\1 1048576/'
sysctl -p "${SYSCTL_CONF_FILE}"
