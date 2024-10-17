FROM amd64/elixir:1.16-otp-26

ARG UID=1000
ARG GID=1000
ARG USER=dfchat
ARG GROUP=dfchat

# Skip post-install steps
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    gnupg \
    inotify-tools \
    wget && \
    wget --no-check-certificate \
    -qO chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get -y --no-install-recommends install ./chrome.deb && \
    rm chrome.deb && \
    apt-get clean

RUN addgroup --system --gid "$GID" "$GROUP" && \
    useradd --system --create-home --uid "$UID" --gid "$GROUP" "$USER"
USER $USER

# Set up the working directory
WORKDIR /app

COPY --chown=$USER:$GROUP mix.exs /app
COPY --chown=$USER:$GROUP mix.lock /app

RUN mix local.hex --force  && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.clean --unused && \
    mix compile
