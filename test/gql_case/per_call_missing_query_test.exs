defmodule GqlCase.PerCallMissingQueryTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  describe "query_gql/1 without query: or load_gql_*" do
    test "raises SetupError" do
      assert_raise GqlCase.SetupError, ~r/No GQL document/, fn ->
        query_gql()
      end
    end
  end
end
