defmodule GqlCase.QueryWithVariablesTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  load_gql("../support/queries/Greet.gql")

  describe "Greet.gql" do
    test "with the expected variables, returns the response of the query" do
      input = %{name: "David"}
      assert %{"data" => %{"greet" => "Hello, David!"}} = query_gql(variables: input)
    end
  end
end
