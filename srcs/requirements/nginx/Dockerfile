FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]