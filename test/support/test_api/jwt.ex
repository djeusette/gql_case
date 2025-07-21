defmodule GqlCase.TestApi.Jwt do
  def encode(_user) do
    {:ok, "test-jwt-token", %{}}
  end

  def decode("test-jwt-token"), do: {:ok, %{id: 1, name: "David"}}
  def decode(_), do: {:error, :invalid_bearer_token}
end
