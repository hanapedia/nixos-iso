FROM nixos/nix

# Setup
WORKDIR /build
COPY . .

# Set build-time Tailscale key
ARG TAILSCALE_AUTH_KEY
ENV TAILSCALE_AUTH_KEY=${TAILSCALE_AUTH_KEY}

# Fake Git repo so flake commands work
RUN git init && \
    git add . && \
    git config user.email "you@example.com" && \
    git config user.name "Flake Builder" && \
    git commit -m "init"
