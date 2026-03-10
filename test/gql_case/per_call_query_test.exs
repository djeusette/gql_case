defmodule GqlCase.PerCallQueryTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  describe "query_gql/1 with query: option" do
    test "executes an inline query" do
      assert %{"data" => %{"hello" => "Hello, World!"}} =
               query_gql(query: "query { hello }")
    end

    test "executes an inline query with variables" do
      assert %{"data" => %{"greet" => "Hello, David!"}} =
               query_gql(
                 query: "query Greet($name: String!) { greet(name: $name) }",
                 variables: %{name: "David"}
               )
    end
  end

  describe "query_gql/1 with query: option and authentication" do
    test "executes an inline query with current_user" do
      assert %{"data" => %{"currentUser" => %{"id" => "1", "name" => "David"}}} =
               query_gql(
                 query: "query { currentUser { id name } }",
                 current_user: %{name: David}
               )
    end
  end
end
