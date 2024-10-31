#!/usr/bin/env bash

mix deps.get
mix deps.clean --unused
mix compile
mix ecto.setup

exec "$@"
