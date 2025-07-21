Application.put_env(:gql_case, GqlCase.TestApi.Endpoint,
  server: true,
  http: [port: 4002],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: String.duplicate("a", 64),
  render_errors: [view: GqlCase.ErrorView, accepts: ~w(json)]
)

{:ok, _} = GqlCase.TestApi.Endpoint.start_link()

ExUnit.start()
