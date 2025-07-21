defmodule GqlCase.TestApi.Schema do
  use Absinthe.Schema

  query do
    field :hello, :string do
      resolve(fn _, _, _ -> {:ok, "Hello, World!"} end)
    end

    field :current_user, :user do
      resolve(fn _, _, %{context: context} ->
        case context do
          %{current_user: user} -> {:ok, user}
          _ -> {:error, "Unauthorized"}
        end
      end)
    end

    field :secret_data, :string do
      resolve(fn
        _, _, %{context: %{api_key: "valid_api_key"}} ->
          {:ok, "Secret information"}

        _, _, _ ->
          {:error, "Missing or invalid API key"}
      end)
    end

    field :greet, :string do
      arg(:name, non_null(:string))

      resolve(fn _, %{name: name}, _ ->
        {:ok, "Hello, #{name}!"}
      end)
    end

    field :headers, list_of(non_null(:header)) do
      resolve(fn _, _, %{context: %{headers: headers}} ->
        formatted_headers =
          Enum.map(headers, fn {key, value} ->
            %{key: key, value: value}
          end)

        {:ok, formatted_headers}
      end)
    end
  end

  object :header do
    field(:key, :string)
    field(:value, :string)
  end

  object :user do
    field(:id, :id)
    field(:name, :string)
  end
end
