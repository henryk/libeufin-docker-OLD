FROM ubuntu:20.04 AS base

ARG COMMIT=704db446040257f338bb731c478fd3fe388e09be
ARG ROOT_USER=root
ARG ROOT_PASSWORD=toortoor

RUN mkdir /app /app/db

FROM base AS builder

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt -y install git python3 python3-distutils build-essential default-jdk && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /src
WORKDIR /src

RUN git clone --depth 1 git://git.taler.net/libeufin.git && cd libeufin && git fetch --depth 1 origin ${COMMIT} && git checkout ${COMMIT}

WORKDIR /src/libeufin

RUN ./bootstrap
RUN ./configure --prefix=/app
RUN make install-nexus install-cli install-sandbox

FROM base AS target

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt -y install python3 python3-click python3-requests default-jre && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app /app

RUN ["./bin/libeufin-nexus", "superuser", "--password", "${ROOT_PASSWORD}", "--db-name", "/app/db/libeufin-nexus.sqlite3", "${ROOT_USER}"]

EXPOSE 5001
VOLUME ["/app/db"]
CMD ["./bin/libeufin-nexus", "serve", "--host", "0.0.0.0", "--db-name", "/app/db/libeufin-nexus.sqlite3"]
