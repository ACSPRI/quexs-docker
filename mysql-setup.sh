#!/bin/bash

#install timezones
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

#install queXS database
mysqladmin create quexs
mysql -uroot quexs < /app/database/quexs.sql
mysql -uroot quexs < /app/database/queXS_AU.sql

