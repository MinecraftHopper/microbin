FROM --platform=$BUILDPLATFORM rust:latest AS build

ARG TARGETPLATFORM
ARG TARGETARCH

WORKDIR /app

RUN \
  DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get -y install ca-certificates tzdata && \
  if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
      apt install -y g++-aarch64-linux-gnu; \
  fi;

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

COPY . .

RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        rustup target add aarch64-unknown-linux-gnu && \
        cargo build --target aarch64-unknown-linux-gnu --release; \
    else \ 
        cargo build --release; \
    fi

RUN ls -l target/release

# https://hub.docker.com/r/bitnami/minideb
FROM bitnami/minideb:latest AS final

# microbin will be in /app
WORKDIR /app

RUN mkdir -p /usr/share/zoneinfo

# copy time zone info
COPY --from=build \
  /usr/share/zoneinfo \
  /usr/share/

COPY --from=build \
  /etc/ssl/certs/ca-certificates.crt \
  /etc/ssl/certs/ca-certificates.crt

# copy built executable
COPY --from=build \
  /app/target/*/microbin \
  /usr/bin/microbin

# Expose webport used for the webserver to the docker runtime
EXPOSE 8080

ENTRYPOINT ["microbin"]
