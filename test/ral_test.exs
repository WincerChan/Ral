defmodule RalTest do
  use ExUnit.Case
  doctest Ral

  test "greets the world" do
    assert Ral.hello() == "A rate limiting tool."
  end
end
