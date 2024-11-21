FROM python:3.5-slim-buster

RUN apt-get update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get update && apt-get install -y nodejs build-essential

WORKDIR /src
COPY . /src

RUN npm install

CMD ["npx", "dociql", "config.yml"]
