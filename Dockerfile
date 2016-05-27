FROM tutum/lamp:latest
MAINTAINER Adam Zammit <adam.zammit@acspri.org.au>
ENV DEBIAN_FRONTEND noninteractive

#Install requrements for queXF
RUN apt-get update && apt-get -y install bzr ghostscript php5-gd php5-adodb libphp-adodb tesseract-ocr php5-cli apache2-utils

#Enable group file authentication for Apache
RUN a2enmod authz_groupfile

#Enable override all for Apache
ADD apache_default /etc/apache2/sites-available/000-default.conf

#Get latest queXF from BZR
RUN rm -fr /app && bzr branch lp:quexf /app

#Configure queXF
ADD config.inc.php /app/config.inc.php
ADD htaccess-verifier /app/.htaccess
ADD htaccess-client /app/client/.htaccess
ADD htaccess-admin /app/admin/.htaccess

#Add directories for images and config and forms
RUN mkdir /images && chown www-data:www-data /images
RUN mkdir /opt/quexf && chown www-data:www-data /opt/quexf
RUN mkdir /forms && chown www-data:www-data /forms

#Add autostart file
ADD startprocess.php /opt/quexf/startprocess.php 
ADD start-quexf.sh /start-quexf.sh
ADD mysql-setup.sh /mysql-setup.sh
RUN chmod 755 /*.sh
#Disabled for now
#ADD supervisord-quexf.conf /etc/supervisor/conf.d/supervisord-quexf.conf

#Add volume for images and config
VOLUME ["/images", "/opt/quexf"]

EXPOSE 80
CMD ["/run.sh"]
