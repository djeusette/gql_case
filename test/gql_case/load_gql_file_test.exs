defmodule GqlCase.LoadGqlFileTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  load_gql_file("../support/queries/hello.gql")

  describe "load_gql_file/1" do
    test "loads query from file" do
      assert @_gql_query
    end
  end
end
