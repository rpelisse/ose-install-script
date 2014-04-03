#/bin/bash
set -e

yum install -y rubygem-openshift-origin-node ruby193-rubygem-passenger-native \
               openshift-origin-port-proxy openshift-origin-node-util
lokkit --nostart --service=ssh
lokkit --nostart --service=https
lokkit --nostart --service=http
lokkit --nostart --port=8000:tcp
lokkit --nostart --port=8443:tcp
chkconfig httpd on
chkconfig network on
chkconfig ntpd on
chkconfig sshd on
chkconfig oddjobd on
chkconfig openshift-node-web-proxy on
