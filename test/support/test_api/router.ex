defmodule GqlCase.TestApi.Router do
  use Phoenix.Router, helpers: true
  import Plug.Conn

  pipeline(:api) do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated_api do
    plug(GqlCase.TestApi.SetCurrentUserPlug)
    plug(GqlCase.TestApi.SetApiKeyPlug)
    plug(GqlCase.TestApi.SetHeadersInContextPlug)
  end

  scope "/" do
    pipe_through(:api)
    pipe_through(:authenticated_api)

    forward("/graphql", Absinthe.Plug,
      schema: GqlCase.TestApi.Schema,
      json_codec: Jason
    )
  end
end
