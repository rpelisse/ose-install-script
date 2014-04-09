#/bin/bash

lokkit --port=35531-65535:tcp
# Ensure the proxy service starts on boot:
chkconfig openshift-port-proxy 'on'
service openshift-port-proxy 'start'

chkconfig openshift-gears 'on'
