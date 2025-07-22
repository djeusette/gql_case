defmodule GqlCase.GqlLoader do
  @moduledoc """
  Defines the functions used to load GQL documents based on the document path.
  """

  defmodule ImportError do
    @moduledoc """
    Exception raised when we can't find a file imported via an
    `#import "some_file.gql"` statement
    """
    defexception [:path, :parent]

    def message(exception) do
      "Failed to load imported file '#{exception.path}' imported in file '#{exception.parent}'"
    end
  end

  defmodule LoaderError do
    @moduledoc """
    Exception raised when we can't find or access a file
    """
    defexception [:path, :reason]

    def message(exception) do
      "Failed to load the document at path: '#{exception.path}' due to: <#{exception.reason}>"
    end
  end

  defmodule ParseError do
    @moduledoc """
    Exception raised when we get a bad result from Absinthe's Parse phase.
    It should provide some useful information as to where the error lays in the document.
    """
    defexception [:path, :err, :line]

    def message(exception) do
      "Absinthe couldn't parse the document at path #{exception.path} due to:
    #{exception.err}
    At Line: #{exception.line}
    (Be sure to check imported documents as well!)"
    end
  end

  @import_regex ~r"#import \"(.*)\""

  @doc """
  When provided a path to a GQL document, expands all import statements and attempts to parses it with Absinthe.

  Returns the query string source with imports appended.

  For example:
  ```elixir
  load_file!("assets/js/MyQuery.gql")
  ```
  """
  @spec load_file!(binary) :: binary
  def load_file!(document_absolute_path) when is_binary(document_absolute_path) do
    unless Path.type(document_absolute_path) == :absolute do
      raise ArgumentError, "Path #{document_absolute_path} is not absolute"
    end

    try_load_file(document_absolute_path)
    |> do_import_expansion(expand_path(document_absolute_path, document_absolute_path))
    |> try_parse_document(document_absolute_path)
  end

  @doc """
  When provided the source code of a GQL document, expands all import statements and attempts to parses it with Absinthe.

  Returns the query string source with imports appended.

  For example:
  ```elixir
  load_string!(@my_query_source, "/path/to/base")
  ```
  """
  @spec load_string!(binary, binary) :: binary
  def load_string!(query_string, base_path)
      when is_binary(query_string) and is_binary(base_path) do
    validate_query_string!(query_string)

    do_import_expansion(query_string, expand_path(base_path, nil))
    |> try_parse_document(base_path)
  end

  defp validate_query_string!(query) do
    # Size limit (10MB) to prevent accidental large strings
    if byte_size(query) > 10_485_760 do
      raise LoaderError, path: "query string", reason: "Query string too large (max 10MB)"
    end

    # Null byte check to prevent issues
    if String.contains?(query, <<0>>) do
      raise LoaderError, path: "query string", reason: "Query string contains null bytes"
    end
  end

  defp expand_path(relative_path, nil), do: relative_path

  defp expand_path(relative_path, absolute_path) do
    if File.dir?(absolute_path) do
      Path.expand(relative_path, absolute_path)
    else
      Path.expand(relative_path, Path.dirname(absolute_path))
    end
  end

  defp do_import_expansion(content, file_absolute_path) do
    matches = Regex.scan(@import_regex, content)

    graphql_inject_import_matches(content, matches, file_absolute_path)
  end

  defp graphql_inject_import_matches(content, matches, file_absolute_path) do
    case matches do
      [] ->
        content

      _ ->
        [_, import_path] = List.first(matches)

        content_to_inject =
          expand_path(import_path, file_absolute_path)
          |> try_import_file(file_absolute_path)
          |> do_import_expansion(expand_path(import_path, file_absolute_path))

        (content <> content_to_inject)
        |> graphql_inject_import_matches(tl(matches), file_absolute_path)
    end
  end

  defp try_import_file(import_path, parent_file) do
    try_load_file(import_path)
  rescue
    _e in LoaderError ->
      reraise ImportError, [path: import_path, parent: parent_file], __STACKTRACE__
  end

  defp try_load_file(path) do
    File.read(path)
    |> case do
      {:ok, file_content} ->
        file_content

      {:error, reason} ->
        raise LoaderError, path: path, reason: reason
    end
  end

  defp try_parse_document(document, src_path) do
    case Absinthe.Phase.Parse.run(%Absinthe.Language.Source{body: document}) do
      {:ok, _blueprint} ->
        document

      {:error, blueprint} ->
        error =
          blueprint.execution.validation_errors
          |> List.first()

        error_location =
          error.locations
          |> List.first()
          |> Map.get(:line)

        raise ParseError, path: src_path, err: error.message, line: error_location
    end
  end
end
