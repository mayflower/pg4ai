# syntax=docker/dockerfile:1.7

FROM postgres:16 AS builder

ARG AGE_VERSION=PG16/v1.5.0-rc0
ARG PGVECTOR_VERSION=v0.7.0
ARG PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    postgresql-server-dev-16 \
    bison \
    flex \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone https://github.com/apache/age.git && \
    cd age && \
    git checkout "${AGE_VERSION}" && \
    make PG_CONFIG="${PG_CONFIG}" && \
    make PG_CONFIG="${PG_CONFIG}" install DESTDIR=/tmp/install-age

RUN git clone https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    git checkout "${PGVECTOR_VERSION}" && \
    make PG_CONFIG="${PG_CONFIG}" && \
    make PG_CONFIG="${PG_CONFIG}" install DESTDIR=/tmp/install-pgvector

FROM postgres:16 AS final

COPY --from=builder /tmp/install-age/usr/lib/postgresql/16/lib/age.so /usr/lib/postgresql/16/lib/
COPY --from=builder /tmp/install-age/usr/share/postgresql/16/extension/age* /usr/share/postgresql/16/extension/

COPY --from=builder /tmp/install-pgvector/usr/lib/postgresql/16/lib/vector.so /usr/lib/postgresql/16/lib/
COPY --from=builder /tmp/install-pgvector/usr/share/postgresql/16/extension/vector* /usr/share/postgresql/16/extension/

COPY docker/init/01-extensions.sql /docker-entrypoint-initdb.d/01-extensions.sql

HEALTHCHECK --interval=5s --timeout=5s --retries=12 \
  CMD pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" || exit 1
