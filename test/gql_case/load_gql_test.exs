defmodule GqlCase.LoadGqlTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  load_gql("../support/queries/hello.gql")

  describe "load_gql/1" do
    test "loads query from file" do
      assert @_gql_query
    end
  end
end
