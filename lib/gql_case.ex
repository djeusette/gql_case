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
          "No GQL document was registered on this module, please use `load_gql_file` or `load_gql_string`"

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
  Call this macro in the module you've loaded a document into using `load_gql_file` or `load_gql_string`.

  Calling this will execute the document loaded into the module against gql path loaded in the module.
  It accepts a keyword list for `options`. These options might be `variables` and `current_user`.

  Returns the query result from the HTTP GQL call.

  For example:
  ```elixir
  result = query_gql(variables: %{}, current_user: %{})
  %{"data" => %{} = result 
  ```
  """
  defmacro query_gql(opts \\ []) do
    quote location: :keep do
      if is_nil(@_gql_query) do
        raise SetupError, reason: :missing_declaration
      end

      import Phoenix.ConnTest, only: [build_conn: 0, post: 3, json_response: 2]

      payload = %{
        query: @_gql_query,
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
