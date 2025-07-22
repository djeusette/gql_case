defmodule GqlCase.DefaultHeadersTest do
  use ExUnit.Case

  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  load_gql_file("../support/queries/Headers.gql")

  describe "Headers.gql" do
    test "returns the default headers" do
      assert %{
               "data" => %{
                 "headers" => [
                   %{"key" => "x-app-version", "value" => "1.0.0"},
                   %{"key" => "content-type", "value" => "application/json"}
                 ]
               }
             } = query_gql()
    end
  end
end
