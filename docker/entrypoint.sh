#!/usr/bin/env bash

mix deps.get
mix deps.clean --unused
mix compile

if [ "$MIX_ENV" = "prod" ]; then
  mix assets.deploy
fi

# Run migrations safely on existing databases without failing on seeds
mix ecto.create || true
mix ecto.migrate

exec "$@"
