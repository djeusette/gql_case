defmodule GqlCase.AdditionalHeadersTest do
  use ExUnit.Case

  use GqlCase.TestApi.DefaultGqlCase,
    headers: [{"x-app-version", "1.0.1"}]

  @endpoint GqlCase.TestApi.Endpoint

  load_gql("../support/queries/SecretData.gql")

  describe "SecretData.gql" do
    test "returns an error when the api key header is not set" do
      assert %{
               "data" => %{"secretData" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Missing or invalid API key",
                   "path" => ["secretData"]
                 }
               ]
             } =
               query_gql()
    end

    test "works with the additional default headers" do
      assert %{"data" => %{"secretData" => "Secret information"}} =
               query_gql(headers: [{"x-api-key", "valid_api_key"}])
    end
  end
end
