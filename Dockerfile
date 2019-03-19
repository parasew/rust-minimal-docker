ARG BINARY_NAME_DEFAULT=mygreatapp
ARG MY_GREAT_CONFIG_DEFAULT="someconfig-default-value"

FROM clux/muslrust:stable as builder
ARG BINARY_NAME_DEFAULT
ENV BINARY_NAME=$BINARY_NAME_DEFAULT
# Build the project with target x86_64-unknown-linux-musl

# Build dummy main with the project's Cargo lock and toml
# This is a docker trick in order to avoid downloading and building 
# dependencies when lock and toml not is modified.
COPY Cargo.lock .
COPY Cargo.toml .
RUN mkdir src \
    && echo "fn main() {print!(\"Dummy main\");} // dummy file" > src/main.rs
RUN set -x && cargo build --target x86_64-unknown-linux-musl --release
# TODO if the BINARY_NAME contains - it vill have deps where - is replaced with _
RUN set -x && rm target/x86_64-unknown-linux-musl/release/deps/$BINARY_NAME*

# Now add the rest of the project and build the real main
COPY src ./src
RUN set -x && cargo build --target x86_64-unknown-linux-musl --release
RUN mkdir -p /build-out
RUN set -x && cp target/x86_64-unknown-linux-musl/release/$BINARY_NAME /build-out/

# Create a minimal docker image 
FROM scratch

ARG BINARY_NAME_DEFAULT
ENV BINARY_NAME=$BINARY_NAME_DEFAULT
ARG MY_GREAT_CONFIG_DEFAULT
ENV MY_GREAT_CONFIG=$MY_GREAT_CONFIG_DEFAULT

ENV RUST_LOG="error,$BINARY_NAME=info"
COPY --from=builder /build-out/$BINARY_NAME /

# Start with an execution list (there is no sh in a scratch image)
# No shell => no variable expansion, |, <, >, etc 
# Hard coded start command
CMD ["/mygreatapp"]