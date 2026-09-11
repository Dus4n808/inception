FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-cli \
    php8.2-mysql \
    mariadb-client \
    curl \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wp \
   https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD [ "php-fpm8.2", "-F", "-O" ]