defmodule GqlCase.TestApi.DefaultGqlCase do
  @moduledoc """
  Default GqlCase for the Test API
  """

  use GqlCase,
    gql_path: "/graphql",
    jwt_bearer_fn: &GqlCase.TestApi.Jwt.encode/1,
    default_headers: [
      {"x-app-version", "1.0.0"}
    ]
end
