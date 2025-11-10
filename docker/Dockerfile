FROM amd64/elixir:1.18-otp-27

ARG UID=1000
ARG GID=1000
ARG USER=siwapp
ARG GROUP=siwapp
ARG CHROME_VERSION=139.0.7258.138-1


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
    wget --no-check-certificate \
      https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb && \
    apt-get install -y ./google-chrome-stable_${CHROME_VERSION}_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f google-chrome-stable_${CHROME_VERSION}_amd64.deb

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
