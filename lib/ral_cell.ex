defmodule Ral.Cell do
  use GenServer
  alias :ets, as: ETS

  @total Application.get_env(:ral, :total)
  @speed Application.get_env(:ral, :speed)
  @member Application.get_env(:ral, :member)

  @doc "start Ral.Cell"
  @spec init(any) :: {:ok, nil}
  def init(_) do
    Ral.Clear.start()
    {:ok, nil}
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    IO.puts("Starting ral...")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec choke(any) :: boolean
  def choke(key) do
    lookup(key)
    |> calcu_rest()
    |> allow?(key)
  end

  @spec calcu_rest({number, DateTime.t()}) :: {float, DateTime.t()}
  defp calcu_rest({rest, prev, d_score?}) do
    n = DateTime.utc_now()
    {DateTime.diff(n, prev, :millisecond) * @speed / 1000 + rest - 1, n, d_score?, prev}
  end

  @spec lookup(any) :: {Integer, DateTime.t()}
  defp lookup(key) do
    case ETS.lookup(@member, key) do
      [{_, prev, rest}] -> {rest, prev, true}
      _ -> {@total, DateTime.utc_now(), false}
    end
  end

  defp allow?({rest, now, d_score?, prev}, key) do
    new_rest = min(rest, @total) |> round()
    send(:clear, {:delete, d_score?, {prev, key}})
    send(:clear, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
    if rest <= 0, do: false, else: true
  end
end
