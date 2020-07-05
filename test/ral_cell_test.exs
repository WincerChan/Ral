defmodule Ral.CellTest do
  use ExUnit.Case

  test "do test succeed" do
    assert Ral.Cell.choke(:two) == true
  end

  @doc """
  please don't add --cover in test command.
  """
  test "do test benchmark..." do
    fun = fn
      _, _, 0 ->
        nil

      fun, key, times ->
        Ral.Cell.choke(key)
        fun.(fun, key, times - 1)
    end

    {elapsed, _} = :timer.tc(fn -> fun.(fun, :one, 100_000) end)
    IO.puts(" Test 100_000 times Ral.Cell.choke/1 elapsed #{elapsed / 1000_000} s")
    assert Ral.Cell.choke(:one) == false
  end
end
