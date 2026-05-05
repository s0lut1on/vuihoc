FROM rust:1.93-slim-bookworm AS builder
WORKDIR /app

# Install curl for utoipa-swagger-ui build script
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock* ./
COPY shared ./shared
COPY auth auth
COPY user user
COPY content content
COPY progress progress
COPY notification notification
COPY media media
COPY question_bank question_bank

# Build shared first so Cargo resolves deps
RUN cargo fetch
RUN cargo build --release -p shared

ARG SERVICE_NAME
RUN cargo build --release -p ${SERVICE_NAME}

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates libpq5 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ARG SERVICE_NAME
COPY --from=builder /app/target/release/${SERVICE_NAME} /app/service

ARG SERVICE_NAME
RUN mkdir -p /app/migrations_tmp
COPY --from=builder /app/${SERVICE_NAME}/migrations /app/migrations_tmp
RUN if [ -d /app/migrations_tmp ]; then mkdir -p /app/${SERVICE_NAME}/migrations \
  && cp -r /app/migrations_tmp/* /app/${SERVICE_NAME}/migrations/ 2>/dev/null || true; fi \
  && rm -rf /app/migrations_tmp

EXPOSE 3000
CMD ["/app/service"]
