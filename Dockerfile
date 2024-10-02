FROM ubuntu/apache2

RUN a2enmod rewrite

USER www-data

COPY container/apache-site.conf /etc/apache2/sites-enabled/000-default.conf

WORKDIR /app

COPY build .

EXPOSE 80

USER root

CMD ["apache2ctl", "-D", "FOREGROUND"]
