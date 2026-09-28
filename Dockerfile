FROM rust:1.91-bookworm AS build

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      nodejs \
      npm \
      pkg-config \
      protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global pnpm@10.9.0 \
    && rustup target add wasm32-unknown-unknown \
    && cargo install wasm-pack --locked

COPY . .

RUN pnpm install --frozen-lockfile \
    && pnpm proto \
    && pnpm build \
    && pnpm --filter client build \
    && cargo build --release --example demo

FROM debian:bookworm-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      ca-certificates \
      libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/target/release/examples/demo /usr/local/bin/voxelize-demo
COPY --from=build /app/examples/client/dist /app/examples/client/dist

CMD ["/usr/local/bin/voxelize-demo"]
