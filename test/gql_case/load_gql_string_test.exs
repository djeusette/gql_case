defmodule GqlCase.LoadGqlStringTest do
  use ExUnit.Case
  use GqlCase.TestApi.DefaultGqlCase

  describe "load_gql_string/1 - basic functionality" do
    defmodule BasicQuery do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("""
      query {
        hello
      }
      """)

      test "loads query from string" do
        assert @_gql_query
        assert String.contains?(@_gql_query, "hello")
      end
    end

    defmodule MultilineQuery do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("""
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
          email
        }
      }
      """)

      test "loads multiline query with variables" do
        assert @_gql_query
        assert String.contains?(@_gql_query, "GetUser")
        assert String.contains?(@_gql_query, "$id: ID!")
      end
    end

    defmodule UnicodeQuery do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("""
      query {
        hello(message: "Héllo Wörld! 你好")
      }
      """)

      test "handles unicode characters in query strings" do
        assert @_gql_query
        assert String.contains?(@_gql_query, "Héllo Wörld! 你好")
      end
    end
  end

  describe "load_gql_string/1 - import resolution" do
    defmodule QueryWithImports do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("""
      #import "../support/assets/Test.frag.gql"

      query {
        hello
      }
      """)

      test "resolves imports from caller directory" do
        assert @_gql_query
        assert String.contains?(@_gql_query, "hello")
        assert String.contains?(@_gql_query, "test fragment to test imports")
        assert String.contains?(@_gql_query, "test fragment to test nested imports")
      end
    end
  end

  describe "load_gql_string/1 - validation constraints" do
    test "rejects query strings that are too large" do
      # Test the validation directly in the GqlLoader module
      large_query =
        """
        query {
          hello
        }
        """ <> String.duplicate("a", 10_485_761)

      assert_raise GqlCase.GqlLoader.LoaderError, ~r/Query string too large/, fn ->
        GqlCase.GqlLoader.load_string!(large_query, "/tmp")
      end
    end

    test "rejects query strings with null bytes" do
      null_byte_query = "query {\n  hello\n}" <> <<0>>

      assert_raise GqlCase.GqlLoader.LoaderError, ~r/contains null bytes/, fn ->
        GqlCase.GqlLoader.load_string!(null_byte_query, "/tmp")
      end
    end
  end

  describe "load_gql_string/1 - edge cases" do
    defmodule EmptyQuery do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("")

      test "handles empty query string" do
        assert @_gql_query == ""
      end
    end

    defmodule MinimalQuery do
      use ExUnit.Case
      use GqlCase.TestApi.DefaultGqlCase

      load_gql_string("{ __typename }")

      test "handles minimal query" do
        assert @_gql_query == "{ __typename }"
      end
    end
  end

  describe "load_gql_string/1 - error handling" do
    test "raises SetupError on double declaration" do
      assert_raise GqlCase.SetupError, ~r/two GraphQL document loading/, fn ->
        defmodule DoubleDeclaration do
          use ExUnit.Case
          use GqlCase.TestApi.DefaultGqlCase

          load_gql_string("query { hello }")
          load_gql_string("query { world }")
        end
      end
    end

    test "raises ParseError for invalid GraphQL syntax" do
      assert_raise GqlCase.GqlLoader.ParseError, fn ->
        defmodule InvalidSyntax do
          use ExUnit.Case
          use GqlCase.TestApi.DefaultGqlCase

          load_gql_string("query { invalid.syntax ]")
        end
      end
    end

    test "raises ImportError for missing import files" do
      assert_raise GqlCase.GqlLoader.ImportError, fn ->
        defmodule MissingImport do
          use ExUnit.Case
          use GqlCase.TestApi.DefaultGqlCase

          load_gql_string("""
          #import "./nonexistent.gql"

          query { hello }
          """)
        end
      end
    end
  end
end
