# syntax=docker/dockerfile:1

# Build stage: compile the benchmark binaries with the pinned nightly toolchain.
# The lockfile requires rustc >= 1.81 (half 2.5.0), so a late-2024 nightly is
# used; the nightly-2024-05-03 suggested in the README predates that MSRV.
FROM rust:bookworm AS builder

RUN rustup toolchain install nightly-2024-09-15 --profile minimal

ENV RUSTFLAGS="-Ctarget-cpu=native -Awarnings"

WORKDIR /build

COPY Cargo.toml Cargo.lock ./
COPY secret-sharing/ secret-sharing/
COPY mpc-net/ mpc-net/
COPY dist-primitive/ dist-primitive/
COPY hyperplonk/ hyperplonk/

RUN cd hyperplonk && cargo +nightly-2024-09-15 build --release -F benchmark \
      --example bench_hyperplonk \
      --example bench_hyperplonk_dataparallel \
      --example bench_cpermcheck \
      --example bench_dpermcheck

# Runtime stage: glibc matches the builder image (debian bookworm).
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends time \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/examples/bench_hyperplonk \
                     /build/target/release/examples/bench_hyperplonk_dataparallel \
                     /build/target/release/examples/bench_cpermcheck \
                     /build/target/release/examples/bench_dpermcheck \
                     /app/
COPY hack/docker/entrypoint.sh /app/run.sh

RUN chmod +x /app/run.sh
RUN mkdir -p /shared /app/output

WORKDIR /app
ENTRYPOINT ["/app/run.sh"]
