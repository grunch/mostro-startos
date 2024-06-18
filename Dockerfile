FROM alpine:3.20

RUN apk update
RUN apk add --no-cache tini && \
    rm -f /var/cache/apk/*

ARG ARCH
ADD ./mostro/target/${ARCH}-unknown-linux-musl/release/mostrod /usr/local/bin/mostrod
RUN chmod +x /usr/local/bin/mostrod
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
