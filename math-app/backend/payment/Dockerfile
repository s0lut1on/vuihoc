FROM rust:1.83-slim-bookworm AS build
WORKDIR /app

# Cache dependencies
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY payment/Cargo.toml payment/Cargo.toml
COPY shared shared
RUN cargo new payment/src 2>/dev/null || true
RUN cargo build --package payment --release 2>/dev/null || true

# Real build
COPY . .
RUN cargo build --package payment --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/target/release/payment /usr/local/bin/payment
CMD ["payment"]
