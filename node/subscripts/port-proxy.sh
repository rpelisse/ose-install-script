#/bin/bash
lokkit --port=35531-65535:tcp
# Run the following command to ensure the proxy service starts on boot:
chkconfig openshift-port-proxy on
#Run the following command to start the service immediately:
service openshift-port-proxy start
chkconfig openshift-gears on
