defmodule Param do
  @atom 1
  @integer 2
  @float 3
  @delimiter 18

  @basic 0
  @compound 1

  def extract(<<@delimiter, @basic, @atom, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [String.to_atom(value) | extract(rest)]
  end

  def extract(<<@delimiter, @basic, @integer, _::32, rest::bytes>>) do
    <<value::integer-64, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@delimiter, @basic, @float, _::32, rest::bytes>>) do
    <<value::float, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@delimiter, @basic, _, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@delimiter, @compound, _, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [extract(value) | extract(rest)]
  end

  def extract(_), do: []
end
