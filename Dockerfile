FROM {{ SRC_IMAGE }}
USER 0

ENV CADDY_BINURL=https://caddyserver.com/api/download?os=linux&arch=amd64
ENV CADDY_CONF=https://bit.ly/nimshim-caddy
ENV NIM_ENTRYPOINT=/opt/nim/start-server.sh

COPY launch.sh /opt

RUN apt-get update && \
    apt-get install -y curl && \
    curl -L -o "/usr/local/bin/caddy" "$CADDY_BINURL" && \
    chmod a+x /usr/local/bin/caddy /opt/launch.sh

ENTRYPOINT ["sh", "-c", "/opt/launch.sh -c $CADDY_CONF -e $NIM_ENTRYPOINT"]
