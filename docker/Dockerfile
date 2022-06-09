FROM ubuntu:20.04

# Set Locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Software versions (https://www.erlang-solutions.com/resources/download.html)
ENV ERLANG_VERSION 1:24.1.7-1
ENV ELIXIR_VERSION 1.13.0-1
ENV PHOENIX_VERSION 1.6.2

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
    wget -O /tmp/node.sh https://deb.nodesource.com/setup_16.x && \
    bash /tmp/node.sh && rm /tmp/node.sh && \
    apt-get install nodejs -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install Erlang & Elixir with Erlang Solutions repo.
RUN wget --no-check-certificate \
    -qO erlang-repo.deb \
    https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i erlang-repo.deb && \
    rm erlang-repo.deb && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    esl-erlang=$ERLANG_VERSION \
    elixir=$ELIXIR_VERSION && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create required dirs
RUN mkdir -p /app /home/ubuntu

# Set user permissions
ARG user_id
ENV user_id $user_id

RUN chown $user_id /app /home/ubuntu
USER $user_id
ENV HOME /home/ubuntu

# Install hex and rebar
RUN mix local.hex --force
RUN mix local.rebar --force

# Install phoenix
RUN mix archive.install hex phx_new $PHOENIX_VERSION

# Set /app as workdir
WORKDIR /app
