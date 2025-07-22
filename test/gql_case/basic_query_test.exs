defmodule GqlCase.BasicQueryTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  load_gql_file("../support/queries/Hello.gql")

  describe "Hello.gql" do
    test "returns the response of the basic query" do
      assert %{"data" => %{"hello" => "Hello, World!"}} = query_gql()
    end
  end
end
