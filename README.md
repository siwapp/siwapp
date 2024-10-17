# Siwapp

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- Populate demo data `mix siwapp.demo`

Or you can use docker:

```bash
docker compose build
docker compose up
docker compose exec -it siwapp mix siwapp.demo  # if you want demo data
```

Now you can visit [`localhost:4010`](http://localhost:4010) from your browser.

To create a new user you can use `mix siwapp.register <your-email@domain.il> <your password>` or
using docker `docker compose exec -it siwapp mix siwapp.register <your-email@domain.il> <your password>`.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## API

Siwapp has a graphQL API.

You can browse the api docs [here](https://htmlpreview.github.io/?https://github.com/siwapp/siwapp/blob/master/api_docs/public/index.html).
