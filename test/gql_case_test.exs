defmodule GqlCaseTest do
  use ExUnit.Case
  doctest GqlCase

  test "greets the world" do
    assert GqlCase.hello() == :world
  end
end
