FROM tutum/lamp:latest
MAINTAINER Adam Zammit <adam.zammit@acspri.org.au>
ENV DEBIAN_FRONTEND noninteractive

#Install requrements for queXS
RUN apt-get update && apt-get -y install bzr php5-cli

#Enable override all for Apache
ADD apache_default /etc/apache2/sites-available/000-default.conf

#Get latest queXS from BZR
RUN rm -fr /app && bzr branch lp:quexs /app

#Configure queXS
ADD config.inc.local.php /app/config.inc.local.php

#Add directories for images and config and forms
RUN chown -R www-data:www-data /app/include/limesurvey/upload && chown -R www-data:www-data /app/include/limesurvey/tmp

#Add autostart file
ADD mysql-setup.sh /mysql-setup.sh
RUN chmod 755 /*.sh

EXPOSE 80
CMD ["/run.sh"]
