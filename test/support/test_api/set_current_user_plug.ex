defmodule GqlCase.TestApi.SetCurrentUserPlug do
  @moduledoc """
  Adds an Absinthe execution context to the Phoenix connection.
  If a valid auth token is in the request header, the corresponding
  user is added to the context which is then available to all
  resolvers. Otherwise, the context is empty.

  This plug runs prior to `Absinthe.Plug` in the `:api` router
  so that the context is set up and `Absinthe.Plug` can extract
  the context from the connection.
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    build_context(conn)
    |> add_context(conn)
  end

  defp build_context(conn) do
    with ["Bearer " <> "test-jwt-token"] <- get_req_header(conn, "authorization"),
         {:ok, user} <- GqlCase.TestApi.Jwt.decode("test-jwt-token") do
      %{current_user: user}
    else
      _ -> nil
    end
  end

  defp add_context(%{current_user: _} = user, %Plug.Conn{private: private} = conn) do
    context =
      private
      |> Map.get(:absinthe, %{})
      |> Map.get(:context, %{})
      |> Map.merge(user)

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp add_context(_, conn), do: conn
end
