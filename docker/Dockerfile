FROM elixir:1.19.4-otp-28

ARG UID=1000
ARG GID=1000
ARG USER=siwapp
ARG GROUP=siwapp
# Skip post-install steps
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update -qq && \
    apt install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      fonts-liberation \
      git \
      gnupg \
      inotify-tools \
      libasound2 \
      libnspr4 \
      libnss3 \
      libu2f-udev \
      libvulkan1 \
      wget \
      xdg-utils && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f google-chrome-stable_current_amd64.deb

RUN addgroup --system --gid "$GID" "$GROUP" && \
    useradd --system --create-home --uid "$UID" --gid "$GROUP" "$USER" && \
    mkdir -p /app && \
    chown "$UID:$GID" /app
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
