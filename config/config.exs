# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :axon,
  ecto_repos: [Axon.Repo]

# Configures the endpoint
config :axon, AxonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YOy5kz2DRZy3wxrYjj00zqTh7we9KPV+ojk83SOcK9M+tkOb4FLJsXXzljItxbFe",
  render_errors: [view: AxonWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Axon.PubSub,
  live_view: [signing_salt: "clt+U3JO"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
