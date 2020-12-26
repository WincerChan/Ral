defmodule Param do
  @atom 1
  @integer 2
  @float 3
  @delimiter 18

  @spec extract(binary) :: [any]
  def extract(<<@delimiter, len::32, @atom, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [String.to_atom(value) | extract(rest)]
  end

  def extract(<<@delimiter, _::32, @integer, rest::bytes>>) do
    <<value::integer-32, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@delimiter, _::32, @float, rest::bytes>>) do
    <<value::float, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@delimiter, len::32, _, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(_), do: []
end
