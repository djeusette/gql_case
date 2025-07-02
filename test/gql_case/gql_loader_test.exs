defmodule GqlCase.GqlLoaderTest do
  use ExUnit.Case, async: true

  alias GqlCase.GqlLoader

  describe "load_file!/1" do
    test "should load a file with imports with its absolute path" do
      file_path =
        Path.expand("../support/assets/Test.gql", Path.dirname(__ENV__.file))

      document = GqlLoader.load_file!(file_path)
      assert String.contains?(document, "#this is just a test fragment to test imports")
      assert String.contains?(document, "#this is just a test fragment to test nested imports")
      assert String.contains?(document, "Item")
    end
  end

  describe "load_string!/1" do
    test "should load a string as a valid query, including an import" do
      string = """
      #import "./test/support/assets/Test.frag.gql"
      {
        Messages {
          ...MessageFields
        }
      }
      """

      document = GqlLoader.load_string!(string)
      assert String.contains?(document, "#this is just a test fragment to test imports")
      assert String.contains?(document, "#this is just a test fragment to test nested imports")
    end
  end
end
