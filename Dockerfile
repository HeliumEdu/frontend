FROM ubuntu/apache2 AS build

RUN apt-get update
RUN apt-get install -y --no-install-recommends make npm nodejs

WORKDIR /app

COPY . .

RUN make install build

######################################################################

FROM ubuntu/apache2 AS frontend

RUN a2enmod rewrite

COPY container/apache-000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY container/apache-ports.conf /etc/apache2/ports.conf
COPY container/apache-mod-servername.conf /etc/apache2/mods-enabled/servername.conf

WORKDIR /app

COPY --from=build --chown=ubuntu:ubuntu /app/build .

EXPOSE 3000

ENV APACHE_RUN_USER=ubuntu

CMD ["apache2ctl", "-D", "FOREGROUND"]
