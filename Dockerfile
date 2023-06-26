ARG  BUILDER_IMAGE=rust:1.70
ARG  DISTROLESS_IMAGE=gcr.io/distroless/cc

############################
# STEP 1 prepare the environment
############################
FROM ${BUILDER_IMAGE} as chef
RUN update-ca-certificates \
    && cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

############################
# STEP 2 cache dependencies and build binary
############################
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release


############################
# STEP 3 build the final small image
############################
FROM ${DISTROLESS_IMAGE}
COPY --from=builder /app/target/release/docker-rs /
CMD ["/docker-rs"]
