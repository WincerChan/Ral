defmodule Ral.Cell do
  use GenServer
  alias :ets, as: ETS

  @total Application.get_env(:ral, :total)
  @speed Application.get_env(:ral, :speed)
  @score Application.get_env(:ral, :score)
  @member Application.get_env(:ral, :member)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    ETS.new(@member, [:set, :public, :named_table])
    ETS.new(@score, [:ordered_set, :public, :named_table])
    {:ok, nil}
  end

  @spec choke(any) :: boolean
  def choke(key) do
    lookup(key)
    |> calcu_rest()
    |> allow?(key)
  end

  defp calcu_rest({rest, prev, d_score?}) do
    n = DateTime.utc_now()

    {DateTime.diff(n, prev, :millisecond) * @speed / 1000 + rest - 1, n, d_score?, prev}
  end

  defp lookup(key) do
    case ETS.lookup(@member, key) do
      [{_, prev, rest}] -> {rest, prev, true}
      _ -> {@total, DateTime.utc_now(), false}
    end
  end

  defp allow?({rest, now, d_score?, prev}, key) do
    new_rest = min(rest, @total) |> Float.ceil(3)
    send(:clear, {:delete, d_score?, {prev, key}})
    send(:clear, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
    if rest <= 0, do: false, else: true
  end
end
