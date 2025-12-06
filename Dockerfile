# ===============================
# Build Stage
# ===============================
ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.1.2
ARG DEBIAN_VERSION=bullseye-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y \
    libssl-dev \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build directory
WORKDIR /app

# Install hex
RUN mix local.hex --force

# Set build ENV
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application code
COPY priv priv
COPY lib lib

# Compile the release (without runtime.exs to avoid baking in env vars)
RUN mix compile

COPY config/runtime.exs config/
RUN mix release

# ===============================
# Runtime Stage
# ===============================
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y \
    openssl \
    libncurses5 \
    locales \
    ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Set runner ENV
ENV MIX_ENV="prod"

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy the release from builder
COPY --from=builder --chown=appuser:appuser /app/_build/${MIX_ENV}/rel/comms ./

# Copy the startup script
COPY --chown=appuser:appuser server.sh ./

RUN chmod +x ./server.sh

# Create tmp directory for daemon mode
RUN mkdir -p /app/tmp && chown appuser:appuser /app/tmp

USER appuser

# Set default port (can be overridden)
ENV PORT=4000

EXPOSE ${PORT}

CMD ["./server.sh"]
