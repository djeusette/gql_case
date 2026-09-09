# credo:disable-for-this-file Credo.Check.Warning.WrongTestFilename
defmodule GqlCase.TestApi.DefaultGqlCase do
  @moduledoc """
  Default GqlCase for the Test API
  """

  alias GqlCase.TestApi.Jwt

  use GqlCase,
    gql_path: "/graphql",
    jwt_bearer_fn: &Jwt.encode/1,
    default_headers: [
      {"x-app-version", "1.0.0"}
    ]
end
