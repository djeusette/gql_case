defmodule GqlCase.OverrideDefaultHeadersTest do
  use ExUnit.Case

  use GqlCase.TestApi.DefaultGqlCase,
    headers: [{"x-api-key", "valid_api_key"}, {"x-app-version", "1.0.1"}]

  @endpoint GqlCase.TestApi.Endpoint

  load_gql_file("../support/queries/Headers.gql")

  describe "Headers.gql" do
    test "returns the overridden headers" do
      assert %{
               "data" => %{
                 "headers" => [
                   %{"key" => "x-api-key", "value" => "valid_api_key"},
                   %{"key" => "x-app-version", "value" => "1.0.1"},
                   %{"key" => "content-type", "value" => "application/json"}
                 ]
               }
             } = query_gql()
    end
  end
end
