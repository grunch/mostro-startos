FROM docker.io/library/rust:1-bookworm as builder
RUN apt-get update && \
    apt-get install -y cmake protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*
RUN USER=root cargo install cargo-auditable
RUN USER=root cargo new --bin mostro
WORKDIR ./mostro
COPY ./mostro/Cargo.toml ./Cargo.toml
COPY ./mostro/Cargo.lock ./Cargo.lock
# build dependencies only (caching)
RUN cargo auditable build --release --locked
# get rid of starter project code
RUN rm src/*.rs

# copy project source code
COPY ./mostro/src ./src

# build auditable release using locked deps
RUN rm ./target/release/deps/mostro*
RUN cargo auditable build --release --locked

FROM docker.io/library/debian:bookworm-slim

ARG APP=/usr/src/app
ARG APP_DATA=/data
ENV APP_USER=appuser

RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP} \
    && mkdir -p ${APP_DATA}

COPY --from=builder /mostro/target/release/mostrod ${APP}/mostro
COPY ./mostro/settings.tpl.toml ${APP}/settings.toml

RUN chown -R $APP_USER:$APP_USER ${APP}

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

WORKDIR ${APP}

ENV RUST_LOG=info
ENV APP_DATA=${APP_DATA}
ENV APP=${APP}