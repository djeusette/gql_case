defmodule GqlCase.TestApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :gql_case

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(GqlCase.TestApi.Router)
end
