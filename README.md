# GqlCase

GqlCase is a comprehensive GraphQL testing library designed specifically for Absinthe projects. It provides powerful macros and utilities to easily test GraphQL queries and mutations with support for authentication, custom headers, and import resolution.

## Key Features

- **Easy GraphQL testing** - Load GraphQL documents from files or strings with simple macros
- **Authentication support** - Seamless JWT bearer token integration for authenticated queries  
- **Flexible header management** - Configure default headers with override capabilities
- **Import resolution** - Support for `#import` statements in GraphQL files
- **Security by design** - Built-in validation and size limits for safe operation

## Installation

Add `gql_case` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gql_case, "~> 0.5"}
  ]
end
```

## Basic Setup

To use GqlCase in your tests, first create a configuration module:

```elixir
defmodule MyApp.GqlCase do
  use GqlCase,
    gql_path: "/graphql",
    jwt_bearer_fn: &MyApp.Guardian.encode_and_sign/1,
    default_headers: [
      {"x-app-version", "1.0.0"},
      {"x-client-type", "test"}
    ]
end
```

Then use it in your test modules:

```elixir
defmodule MyApp.UserQueryTest do
  use ExUnit.Case
  use MyApp.GqlCase

  @endpoint MyApp.Endpoint

  load_gql_file("queries/GetUser.gql")

  test "fetches user data" do
    result = query_gql(variables: %{id: "123"})
    assert %{"data" => %{"user" => %{"id" => "123"}}} = result
  end
end
```

## Core Configuration

The `use GqlCase` directive accepts several required and optional parameters:

### Required Parameters

- **`gql_path`** - The endpoint path for GraphQL requests (e.g., `"/graphql"`)
- **`jwt_bearer_fn`** - Function to generate JWT tokens for authentication (arity 1)

### Optional Parameters

- **`default_headers`** - List of default headers applied to all requests

```elixir
defmodule MyApp.GqlCase do
  use GqlCase,
    gql_path: "/api/graphql",
    jwt_bearer_fn: &MyApp.Auth.create_token/1,
    default_headers: [
      {"accept", "application/json"},
      {"x-api-version", "v1"}
    ]
end
```

## Loading GraphQL Documents

GqlCase provides two ways to load GraphQL documents into your test modules:

### Loading from Files

Use `load_gql_file/1` to load GraphQL documents from external files:

```elixir
defmodule MyApp.ProductTest do
  use MyApp.GqlCase
  
  # Load from relative path
  load_gql_file("queries/GetProducts.gql")
  
  test "gets products" do
    result = query_gql()
    assert %{"data" => %{"products" => products}} = result
  end
end
```

### Loading from Strings

Use `load_gql_string/1` for inline GraphQL queries:

```elixir
defmodule MyApp.SimpleTest do
  use MyApp.GqlCase
  
  load_gql_string """
  query GetHello {
    hello
  }
  """
  
  test "says hello" do
    result = query_gql()
    assert %{"data" => %{"hello" => "Hello, World!"}} = result
  end
end
```

### Import System

GqlCase supports GraphQL import statements for modular query organization:

```graphql
# fragments/UserFields.gql
fragment UserFields on User {
  id
  name
  email
}

# queries/GetUser.gql  
#import "fragments/UserFields.gql"

query GetUser($id: ID!) {
  user(id: $id) {
    ...UserFields
  }
}
```

## Basic Query Execution

Execute loaded GraphQL documents using the `query_gql/1` macro:

### Simple Queries

```elixir
result = query_gql()
assert %{"data" => %{"hello" => "Hello, World!"}} = result
```

### Queries with Variables

```elixir
result = query_gql(variables: %{id: "123", name: "John"})
assert %{"data" => %{"user" => %{"id" => "123"}}} = result
```

## Authentication Features

GqlCase seamlessly integrates with JWT-based authentication systems:

### Authenticated Queries

Pass a `current_user` to automatically generate and include JWT tokens:

```elixir
user = %{id: "123", email: "user@example.com"}
result = query_gql(current_user: user)
```

### JWT Bearer Function

The JWT bearer function should accept a user struct or map and return `{:ok, token, claims}`:

```elixir
defmodule MyApp.Auth do
  def create_token(user) do
    Guardian.encode_and_sign(user, %{}, ttl: {1, :hour})
  end
end
```

## Header Management

GqlCase provides a flexible header management system with multiple levels of configuration:

### Default Headers

Set default headers that apply to all requests in your configuration:

```elixir
use GqlCase,
  gql_path: "/graphql", 
  jwt_bearer_fn: &MyApp.Auth.create_token/1,
  default_headers: [
    {"x-app-version", "1.0.0"},
    {"accept-language", "en-US"}
  ]
```

### Module-Specific Headers

Override or add headers for specific test modules:

```elixir
defmodule MyApp.AdminTest do
  use ExUnit.Case
  use MyApp.GqlCase, headers: [
    {"x-admin-role", "super"},
    {"x-feature-flag", "admin-panel"}
  ]
  
  load_gql_string "query { adminData }"
  
  test "accesses admin data" do
    result = query_gql()
    # Request includes both default headers and module-specific headers
  end
end
```

### Runtime Header Overrides

Add or override headers for individual queries:

```elixir
result = query_gql(
  variables: %{id: "123"},
  headers: [
    {"x-request-id", "abc-123"},
    {"x-app-version", "2.0.0"}  # Overrides default
  ]
)
```

### Header Priority System

Headers are merged with the following priority (highest to lowest):

1. **Runtime headers** (passed to `query_gql/1`)
2. **Authorization header** (generated from `current_user`)
3. **Module-specific headers** (from `use MyApp.GqlCase, headers: [...]`)
4. **Default headers** (from configuration)
5. **Built-in headers** (`{"content-type", "application/json"}`)

## Advanced Usage

### Error Handling Patterns

GqlCase validates GraphQL documents and provides detailed error information:

```elixir
# File not found
load_gql_file("nonexistent.gql")  # Raises LoaderError

# Invalid GraphQL syntax  
load_gql_string "query { invalid syntax }"  # Raises ParseError

# Missing import
load_gql_file("query_with_missing_import.gql")  # Raises ImportError
```

### Import Resolution

Imports are resolved relative to the importing file's directory:

```
project/
├── test/
│   └── queries/
│       ├── fragments/
│       │   └── UserFields.gql
│       └── GetUser.gql
```

```graphql
# In GetUser.gql:
#import "fragments/UserFields.gql"
```

### Unicode Support

GqlCase fully supports Unicode in GraphQL documents:

```elixir
load_gql_string """
query GetGreeting($name: String!) {
  greeting(name: $name)
}
"""

result = query_gql(variables: %{name: "José"})
```

### Security Constraints

Built-in security measures include:

- **File size limits** - Query strings limited to 10MB
- **Null byte detection** - Prevents null byte injection
- **Path validation** - Ensures safe file path resolution

## API Reference

### Macros

#### `load_gql_file(file_path)`

Loads a GraphQL document from a file path relative to the calling module.

- **Arguments**: `file_path` (string) - Path to the GraphQL file
- **Raises**: `LoaderError` if file cannot be read, `ParseError` if GraphQL is invalid

#### `load_gql_string(query_string)`

Loads a GraphQL document from an inline string.

- **Arguments**: `query_string` (string) - GraphQL query/mutation string  
- **Raises**: `ParseError` if GraphQL is invalid

#### `query_gql(opts \\ [])`

Executes the loaded GraphQL document against the configured endpoint.

- **Options**:
  - `variables` - Map of GraphQL variables (default: `%{}`)
  - `current_user` - User map for JWT authentication (default: `nil`)
  - `headers` - Additional request headers (default: `[]`)
- **Returns**: Decoded JSON response from GraphQL endpoint

### Error Types

#### `GqlCase.SetupError`

Raised when GqlCase is configured incorrectly:

- `:missing_path` - No `gql_path` provided
- `:missing_jwt_bearer_fn` - No JWT function provided  
- `:invalid_jwt_bearer_fn` - JWT function has wrong arity
- `:double_declaration` - Multiple `load_gql_*` calls in same module

#### `GqlCase.GqlLoader.LoaderError` 

Raised when files cannot be loaded:

- Contains `path` and `reason` for debugging

#### `GqlCase.GqlLoader.ImportError`

Raised when imported files cannot be found:

- Contains `path` and `parent` file information

#### `GqlCase.GqlLoader.ParseError`

Raised when GraphQL documents are invalid:

- Contains `path`, error message, and line number

---

For more examples and advanced usage patterns, see the [test suite](test/) in this repository.
