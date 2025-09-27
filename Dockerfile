FROM ubuntu:24.04 AS build

RUN apt-get --fix-missing update
RUN apt-get install -y curl gnupg
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs rsync

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

COPY . .

RUN npm install
RUN npm run build-deploy

######################################################################

FROM ubuntu:24.04 AS frontend

RUN apt-get --fix-missing update
RUN apt-get install -y --no-install-recommends apache2

RUN a2enmod rewrite

COPY container/apache-000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY container/apache-ports.conf /etc/apache2/ports.conf
COPY container/apache-mod-servername.conf /etc/apache2/mods-enabled/servername.conf

ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_RUN_USER=ubuntu

WORKDIR /app

COPY --from=build --chown=ubuntu:ubuntu /app/build .

EXPOSE 3000

CMD ["apache2ctl", "-D", "FOREGROUND"]
