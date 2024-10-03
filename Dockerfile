FROM ubuntu/apache2

RUN a2enmod rewrite

USER www-data

COPY container/apache-site.conf /etc/apache2/sites-enabled/000-default.conf
COPY container/apache-ports.conf /etc/apache2/ports.conf

WORKDIR /app

COPY build .

EXPOSE 3000

USER root

CMD ["apache2ctl", "-D", "FOREGROUND"]
