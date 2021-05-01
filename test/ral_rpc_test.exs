defmodule ParamTest do
  use ExUnit.Case

  # defp benchmark(_, 0), do: nil

  # defp benchmark(key, times) do
  #   Ral.Cell.choke(key)
  #   benchmark(key, times - 1)
  # end

  # test "do test empty list" do
  #   assert Param.extract(<<18, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>) == [[]]
  # end

  def bench() do
    for _ <- 0..100 do
      <<18, 0, 0, 0, 0, 0, 6, 230, 153, 174, 233, 128, 154>>
    end
    |> Enum.join()
    |> Param.extract()
  end

  # test "do test one element" do
  #   results =
  #     for _ <- 0..100 do
  #       "普通"
  #     end

  #   IO.inspect(:timer.tc(__MODULE__, :bench, []))

  #   assert bench() ==
  #            results
  # end

  # test "do complex element" do
  #   assert Param.extract(
  #            <<18, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 1, 0, 0, 0, 0, 0, 0, 0, 0, 17, 18, 0, 0, 0,
  #              0, 0, 0, 0, 0, 0, 6, 230, 153, 174, 233, 128, 154, 13, 10>>
  #          ) == [[], ["普通"]]
  # end
  def bench_two(0), do: nil

  def bench_two(n) do
    String.split("choke$$10$0.1", "$")
    bench_two(n - 1)
  end

  def bench_one(0), do: nil

  def bench_one(n) do
    Param.extract(
      <<18, 0, 1, 0, 0, 0, 5, 99, 104, 111, 107, 101, 18, 0, 0, 0, 0, 0, 0, 18, 0, 2, 0, 0, 0, 8,
        0, 0, 0, 0, 0, 0, 0, 10, 18, 0, 3, 0, 0, 0, 8, 63, 185, 153, 153, 153, 153, 153, 154, 13,
        10>>
    )

    bench_one(n - 1)
  end

  test "do all fk" do
    IO.inspect(:timer.tc(__MODULE__, :bench_one, [1_000_000]))
    IO.inspect(:timer.tc(__MODULE__, :bench_two, [1_000_000]))

    assert Param.extract(
             <<18, 0, 1, 0, 0, 0, 5, 99, 104, 111, 107, 101, 18, 0, 0, 0, 0, 0, 0, 18, 0, 2, 0, 0,
               0, 8, 0, 0, 0, 0, 0, 0, 0, 10, 18, 0, 3, 0, 0, 0, 8, 63, 185, 153, 153, 153, 153,
               153, 154, 13, 10>>
           ) == [:choke, "", 10, 0.1]
  end

  def bench_two(0), do: nil

  def bench_two(n) do
    [a | [b | [c | [d]]]] = String.split("choke$ $10$0.1", "$")
    String.to_atom(a)
    String.to_integer(c)
    String.to_float(d)
    bench_two(n - 1)
  end

  def bench_one(0), do: nil

  def bench_one(n) do
    Param.extract(
      <<18, 0, 1, 0, 0, 0, 5, 99, 104, 111, 107, 101, 18, 0, 0, 0, 0, 0, 0, 18, 0, 2, 0, 0, 0, 8,
        0, 0, 0, 0, 0, 0, 0, 10, 18, 0, 3, 0, 0, 0, 8, 63, 185, 153, 153, 153, 153, 153, 154, 13,
        10>>
    )

    bench_one(n - 1)
  end

  def run do
    IO.inspect(:timer.tc(__MODULE__, :bench_one, [1_000_000]))
    IO.inspect(:timer.tc(__MODULE__, :bench_two, [1_000_000]))
  end
end
