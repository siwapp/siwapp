# Siwapp

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Or you can use docker:

```bash
docker compose build
docker compose run --rm siwapp mix setup   # execute only the first time
docker compose up
```

Now you can visit [`localhost:4010`](http://localhost:4000) from your browser.

To create a new user you can use `mix siwapp.register <your-email@domain.il> <your password>` or
using docker `docker compose run --rm siwapp mix siwapp.register <your-email@domain.il> <your password>`.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## API

Siwapp has a graphQL API.

You can browse the api docs [here](https://htmlpreview.github.io/?https://github.com/siwapp/siwapp/blob/master/api_docs/public/index.html).

