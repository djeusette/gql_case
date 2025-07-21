defmodule GqlCase.TestApi.SetHeadersInContextPlug do
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

  def init(opts), do: opts

  def call(conn, _) do
    build_context(conn)
    |> add_context(conn)
  end

  defp build_context(%Plug.Conn{req_headers: headers}), do: %{headers: headers}

  defp add_context(%{} = new_context, %Plug.Conn{private: private} = conn) do
    context =
      private
      |> Map.get(:absinthe, %{})
      |> Map.get(:context, %{})
      |> Map.merge(new_context)

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp add_context(_, conn), do: conn
end
