defmodule Param do
  @atom 1
  @integer 2
  @float 3

  @basic 0
  @list 1
  @hash 2

  def extract(<<@basic::4, @atom::4, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [String.to_atom(value) | extract(rest)]
  end

  def extract(<<@basic::4, @integer::4, _::32, rest::bytes>>) do
    <<value::integer-64, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@basic::4, @float::4, _::32, rest::bytes>>) do
    <<value::float, rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@basic::4, _::4, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [value | extract(rest)]
  end

  def extract(<<@list::4, _, len::32, rest::bytes>>) do
    <<value::bytes-size(len), rest::bytes>> = rest
    [extract(value) | extract(rest)]
  end

  def extract(_), do: []
end
