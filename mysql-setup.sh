#!/bin/bash

mysqladmin create quexf
mysql -uroot quexf < /app/database/quexf.sql

mysql -uroot quexf << EOF
INSERT INTO verifiers (description,http_username) VALUES ('Administrator','admin');
EOF

VOLUME_HOME="/opt/quexf"

if [[ ! -d $VOLUME_HOME/password ]]; then
    echo "=> An empty or uninitialized password database at $VOLUME_HOME"
    echo "=> Installing HTACCESS password database ... "
    echo "=> (default username: admin default password: password)"
    htpasswd -c -B -b $VOLUME_HOME/password admin password
    echo 'admin: admin' > $VOLUME_HOME/group
    echo 'verifier: admin' >> $VOLUME_HOME/group
    echo 'client: admin' >> $VOLUME_HOME/group
    echo "=> Done!"  
else
    echo "=> Using an existing password directory of queXF"
fi
