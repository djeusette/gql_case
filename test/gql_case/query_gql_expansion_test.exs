defmodule GqlCase.QueryGqlExpansionTest do
  use ExUnit.Case, async: true

  describe "query_gql/1 with a loaded document" do
    test "compiles without warnings" do
      {_module, diagnostics} =
        compile_sample("""
        load_gql_file("../support/queries/Hello.gql")

        def run, do: query_gql(variables: %{})
        """)

      assert diagnostics == []
    end

    test "falls back to the loaded document when no query: option is given" do
      {module, _diagnostics} =
        compile_sample("""
        load_gql_file("../support/queries/Greet.gql")

        def run(name, user), do: query_gql(variables: %{name: name}, current_user: user)
        """)

      assert %{"data" => %{"greet" => "Hello, David!"}} = module.run("David", %{name: "David"})
    end

    test "uses the query: option over the loaded document" do
      {module, diagnostics} =
        compile_sample("""
        load_gql_string("query { hello }")

        def run do
          query_gql(
            query: "query Greet($name: String!) { greet(name: $name) }",
            variables: %{name: "Override"}
          )
        end
        """)

      assert diagnostics == []
      assert %{"data" => %{"greet" => "Hello, Override!"}} = module.run()
    end
  end

  describe "query_gql/1 without a loaded document" do
    test "compiles without warnings" do
      {_module, diagnostics} = compile_sample("def run, do: query_gql(variables: %{})")

      assert diagnostics == []
    end

    test "raises SetupError with reason :missing_declaration" do
      {module, _diagnostics} = compile_sample("def run, do: query_gql(variables: %{})")

      error = assert_raise(GqlCase.SetupError, ~r/No GQL document/, fn -> module.run() end)
      assert error.reason == :missing_declaration
    end

    test "uses the query: option" do
      {module, diagnostics} = compile_sample(~S|def run, do: query_gql(query: "query { hello }")|)

      assert diagnostics == []
      assert %{"data" => %{"hello" => "Hello, World!"}} = module.run()
    end
  end

  # Compiles `body` inside a fresh module set up like a regular GqlCase test
  # module and returns the module with the diagnostics emitted while compiling
  # it, as `{severity, message}` pairs. The file is set to this test file so
  # that `load_gql_file/1` resolves relative paths the same way as real tests.
  defp compile_sample(body) do
    module = Module.concat(__MODULE__, "Sample#{System.unique_integer([:positive])}")

    source = """
    defmodule #{inspect(module)} do
      use GqlCase.TestApi.DefaultGqlCase
      @endpoint GqlCase.TestApi.Endpoint

    #{body}
    end
    """

    {_compiled, diagnostics} =
      Code.with_diagnostics(fn -> Code.compile_string(source, __ENV__.file) end)

    on_exit(fn ->
      :code.purge(module)
      :code.delete(module)
    end)

    {module, Enum.map(diagnostics, &{&1.severity, &1.message})}
  end
end
