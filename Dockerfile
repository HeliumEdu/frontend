FROM ubuntu/apache2

RUN a2enmod rewrite

COPY container/apache-000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY container/apache-ports.conf /etc/apache2/ports.conf
COPY container/apache-mod-servername.conf /etc/apache2/mods-enabled/servername.conf

WORKDIR /app

COPY build .

EXPOSE 3000

ENV APACHE_RUN_USER=ubuntu

CMD ["apache2ctl", "-D", "FOREGROUND"]
