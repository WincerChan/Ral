defmodule Ral.CellTest do
  use ExUnit.Case

  # defp benchmark(_, 0), do: nil

  # defp benchmark(key, times) do
  #   Ral.Cell.choke(key)
  #   benchmark(key, times - 1)
  # end

  defp permutations([]), do: [[]]

  defp permutations(list),
    do: for(elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest])

  test "do test succeed" do
    assert Ral.Cell.choke(:live) == true
  end

  defp test_benchmark(0), do: nil

  defp test_benchmark(n) do
    pms =
      permutations(["a", "b", "c", "d", "e", "f", "g", "h", "i"])
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.to_atom/1)

    {elapsed, _} =
      :timer.tc(fn ->
        pms |> Enum.map(&Ral.Cell.choke/1)
      end)

    IO.puts(" Test#{n} #{length(pms)} times Ral.Cell.choke/1 elapsed #{elapsed / 1000_000} s")
    test_benchmark(n - 1)
  end

  test "do test benchmark ..." do
    test_benchmark(10)
  end
end
