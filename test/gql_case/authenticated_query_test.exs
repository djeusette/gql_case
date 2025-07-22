defmodule GqlCase.AuthenticatedQueryTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  @endpoint GqlCase.TestApi.Endpoint

  load_gql_file("../support/queries/CurrentUser.gql")

  describe "CurrentUser.gql" do
    test "when not authenticated, returns an error" do
      assert %{
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Unauthorized",
                   "path" => ["currentUser"]
                 }
               ]
             } = query_gql()
    end

    test "when authenticated, returns the right response" do
      assert %{"data" => %{"currentUser" => %{"id" => "1", "name" => "David"}}} =
               query_gql(current_user: %{name: David})
    end
  end
end
