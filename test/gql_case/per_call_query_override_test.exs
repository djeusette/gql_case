defmodule GqlCase.PerCallQueryOverrideTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  load_gql_string("query { hello }")

  describe "query: option overrides @_gql_query" do
    test "uses the inline query instead of the module-level query" do
      assert %{"data" => %{"greet" => "Hello, Override!"}} =
               query_gql(
                 query: "query Greet($name: String!) { greet(name: $name) }",
                 variables: %{name: "Override"}
               )
    end

    test "falls back to module-level query when no query: option" do
      assert %{"data" => %{"hello" => "Hello, World!"}} = query_gql()
    end
  end
end
