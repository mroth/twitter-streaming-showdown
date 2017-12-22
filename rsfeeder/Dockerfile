ARG PROJECT=rsfeeder

FROM ekidd/rust-musl-builder AS builder
ARG PROJECT

# make a skeleton project to cache dependency compilation
RUN USER=rust cargo new $PROJECT
WORKDIR $PROJECT
ADD Cargo.toml Cargo.lock ./
RUN cargo build
RUN cargo build --release
RUN rm -r ./src

# build our release application
ADD src ./src
RUN cargo build --release

# build image for release artifact
FROM alpine:latest
ARG PROJECT
RUN apk --no-cache add ca-certificates
COPY --from=builder \
    /home/rust/src/${PROJECT}/target/x86_64-unknown-linux-musl/release/${PROJECT} \
    /usr/local/bin/
CMD /usr/local/bin/rsfeeder
