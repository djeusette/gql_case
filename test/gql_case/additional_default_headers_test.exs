defmodule GqlCase.AdditionalDefaultHeadersTest do
  use ExUnit.Case

  use GqlCase.TestApi.DefaultGqlCase,
    headers: [{"x-api-key", "valid_api_key"}, {"x-app-version", "1.0.1"}]

  @endpoint GqlCase.TestApi.Endpoint

  load_gql("../support/queries/SecretData.gql")

  describe "SecretData.gql" do
    test "works with the additional default headers" do
      assert %{"data" => %{"secretData" => "Secret information"}} = query_gql()
    end
  end
end
