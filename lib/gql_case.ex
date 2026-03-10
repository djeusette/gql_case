defmodule GqlCase do
  @moduledoc """
  This module defines helper macros to work with Graphql and Guardian
  """

  alias __MODULE__.GqlLoader
  alias Plug.Conn

  defmodule SetupError do
    @moduledoc """
    Exception that is raised when GqlCase is called improperly
    """
    defexception [:reason]

    def message(exception) do
      case exception.reason do
        :double_declaration ->
          "You cannot declare two GraphQL document loading statements in the same module."

        :missing_declaration ->
          "No GQL document was provided, please use the `query:` option or `load_gql_file`/`load_gql_string`"

        :missing_path ->
          "No path to the GQL api was registered on this module, please provide `gql_path`"

        :missing_jwt_bearer_fn ->
          "No jwt bearer function was registered on this module, please provide `jwt_bearer_fn`"

        :invalid_jwt_bearer_fn ->
          "An invalid jwt bearer function was registered on this module, please provide a function with arity 1"
      end
    end
  end

  defmacro __using__(opts) do
    quote location: :keep do
      @_gql_path Keyword.get(unquote(opts), :gql_path)
      @_jwt_bearer_fn Keyword.get(unquote(opts), :jwt_bearer_fn)
      @_default_headers Keyword.get(unquote(opts), :default_headers, [])

      if is_nil(@_gql_path) do
        raise SetupError, reason: :missing_path
      end

      if is_nil(@_jwt_bearer_fn) do
        raise SetupError, reason: :missing_jwt_bearer_fn
      end

      if not is_function(@_jwt_bearer_fn, 1) do
        raise SetupError, reason: :invalid_jwt_bearer_fn
      end

      if not is_nil(@_default_headers) and not is_list(@_default_headers) do
        raise SetupError, reason: :invalid_default_headers
      end

      defmacro __using__(inner_opts) do
        quote location: :keep do
          import GqlCase

          @_specific_default_headers Keyword.get(unquote(inner_opts), :headers, [])

          default_headers =
            GqlCase.merge_headers_with_priority([
              unquote(@_default_headers),
              @_specific_default_headers
            ])

          Module.put_attribute(__MODULE__, :_gql_path, unquote(@_gql_path))
          Module.put_attribute(__MODULE__, :_jwt_bearer_fn, unquote(@_jwt_bearer_fn))
          Module.put_attribute(__MODULE__, :_default_headers, default_headers)
          Module.register_attribute(__MODULE__, :_gql_query, persist: false)
        end
      end
    end
  end

  @doc """
  Call this macro in the module you wish to load your GQL document from a file.

  It takes one argument, the path to a GQL file that contains a GraphQL query or mutation.

  For example:
  ```elixir
  defmodule MyApp do
    load_gql_file "assets/js/queries/MyQuery.gql"
    # ...
  end
  ```
  """
  defmacro load_gql_file(file_path) do
    quote do
      if Module.get_attribute(unquote(__CALLER__.module), :_gql_query) != nil do
        raise GqlCase.SetupError, reason: :double_declaration
      end

      caller_directory = Path.dirname(unquote(__CALLER__.file))
      absolute_path = Path.expand(unquote(file_path), caller_directory)
      document = GqlLoader.load_file!(absolute_path)
      Module.put_attribute(unquote(__CALLER__.module), :_gql_query, document)
    end
  end

  @doc """
  Call this macro in the module you wish to load your GQL document from a query string.

  It takes one argument, a string containing a GraphQL query or mutation.

  For example:
  ```elixir
  defmodule MyApp do
    load_gql_string \"\"\"
    query {
      hello
    }
    \"\"\"
    # ...
  end
  ```
  """
  defmacro load_gql_string(query_string) do
    quote do
      if Module.get_attribute(unquote(__CALLER__.module), :_gql_query) != nil do
        raise GqlCase.SetupError, reason: :double_declaration
      end

      caller_directory = Path.dirname(unquote(__CALLER__.file))
      document = GqlLoader.load_string!(unquote(query_string), caller_directory)
      Module.put_attribute(unquote(__CALLER__.module), :_gql_query, document)
    end
  end

  @doc """
  Execute a GraphQL query or mutation against the configured endpoint.

  The query is resolved from two sources, in priority order:
  1. The `query:` option (runtime) — used if provided
  2. The `@_gql_query` module attribute — fallback (set via `load_gql_file` or `load_gql_string`)

  If neither is present, raises `SetupError`.

  ## Options

    * `query` - a GraphQL query string (optional if `load_gql_file`/`load_gql_string` was used)
    * `variables` - a map of GraphQL variables (default: `%{}`)
    * `current_user` - a user map for JWT authentication (optional)
    * `headers` - a list of `{key, value}` header tuples (optional)

  ## Examples

      # Per-call inline query
      query_gql(query: "query { hello }", variables: %{})

      # Using module-level query (legacy)
      load_gql_file "queries/Hello.gql"
      query_gql(variables: %{})
  """
  defmacro query_gql(opts \\ []) do
    quote location: :keep do
      query =
        Keyword.get(unquote(opts), :query) ||
          @_gql_query ||
          raise SetupError, reason: :missing_declaration

      import Phoenix.ConnTest, only: [build_conn: 0, post: 3, json_response: 2]

      payload = %{
        query: query,
        variables: Keyword.get(unquote(opts), :variables, %{})
      }

      build_conn()
      |> add_headers(@_default_headers)
      |> add_headers(@_jwt_bearer_fn, unquote(opts))
      |> post(@_gql_path, JSON.encode!(payload))
      |> json_response(200)
    end
  end

  def add_headers(%Conn{} = conn, headers) when is_list(headers) do
    Enum.reduce(headers, conn, fn {key, value}, conn ->
      Conn.put_req_header(conn, key, value)
    end)
  end

  def add_headers(%Conn{} = conn, jwt_bearer_fn, opts \\ []) when is_function(jwt_bearer_fn, 1) do
    query_headers = Keyword.get(opts, :headers, [])

    headers =
      merge_headers_with_priority([
        default_headers(),
        List.wrap(query_headers),
        authorization_header(jwt_bearer_fn, opts)
      ])

    add_headers(conn, headers)
  end

  def merge_headers_with_priority(header_lists) do
    header_lists
    |> Enum.flat_map(& &1)
    |> Enum.reverse()
    |> Enum.uniq_by(fn {key, _value} -> String.downcase(key) end)
    |> Enum.reverse()
  end

  defp default_headers do
    [{"content-type", "application/json"}]
  end

  defp authorization_header(jwt_bearer_fn, opts) do
    with %{} = user <- Keyword.get(opts, :current_user),
         {:ok, session_token, _claims} <- jwt_bearer_fn.(user) do
      [{"authorization", "Bearer #{session_token}"}]
    else
      nil -> []
    end
  end
end
