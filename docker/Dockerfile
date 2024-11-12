FROM amd64/elixir:1.16-otp-26

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

# Install hex and rebar
RUN mix local.hex --force
RUN mix local.rebar --force

# Create required dirs
RUN mkdir /app

# Set /app as workdir
WORKDIR /app
