# Use an official Elixir image with Ubuntu as the base
FROM ubuntu:22.04

# Set locale to UTF-8
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # locales \
    # locale-gen en_US.UTF-8 \
    # update-locale LANG=en_US.UTF-8 \
    inotify-tools \
    protobuf-compiler \
    clang \
    curl \
    git \
    libssl-dev \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libssh-dev \
    libgl1-mesa-glx \
    nodejs \
    npm \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set locale to UTF-8
# ENV LANG=en_US.UTF-8
# ENV LANGUAGE=en_US:en
# ENV LC_ALL=en_US.UTF-8

# Install ASDF version manager
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0

# Set up environment variables for ASDF
ENV PATH="/root/.asdf/bin:/root/.asdf/shims:${PATH}"

# Install Erlang and Elixir via ASDF
RUN ~/.asdf/bin/asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
RUN ~/.asdf/bin/asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# Copy .tool-versions for exact version management
COPY .tool-versions /root/.tool-versions

# Install the required versions of Erlang and Elixir
RUN ~/.asdf/bin/asdf install

# Install Rust for NIF-based dependencies
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Set working directory inside the container
WORKDIR /app

# Copy mix dependencies files
COPY mix.exs mix.lock ./
COPY config config

# install hex
RUN mix archive.install hex phx_new

# Copy the entire project
COPY . .
# # Recompile libphysics (rust code)
# RUN rm -rf _build/

RUN mix local.hex --force && \
    mix local.rebar --force

# Ensure Rust NIF is properly compiled
RUN mix deps.get
RUN mix deps.compile rustler
RUN mix compile

# Build and install the Rust NIF
RUN cd apps/arena/native/physics && cargo clean && cargo build --release

# Expose the Phoenix port
EXPOSE 4000
EXPOSE 4100
EXPOSE 3000

# Start the application
CMD ["mix", "phx.server"]
