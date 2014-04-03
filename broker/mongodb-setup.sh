#/bin/bash

yum install mongodb-server
sed -i /etc/mongodb.conf \
    -e 's/auth=true/auth=true/' \
    -e 's/^bind_ip = .*$/bind_ip = 0.0.0.0/'
echo "smallfiles=true" >> /etc/mongodb.conf  #TODO: make this idempotent
lokkit  --port=27017:tcp
service mongod start

