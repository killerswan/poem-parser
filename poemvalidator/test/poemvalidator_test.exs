defmodule PoemvalidatorTest do
  use ExUnit.Case

  def read_all(path) do
    file = File.open!(path, [:read, :utf8])
    digits = IO.read(file, :line) |> String.strip
    File.close(file)
    digits
  end

  test "poem is being read from file" do
    assert "For a time" == read_all("../poem.txt") |> String.slice 0..9
  end

  test "pi is being read from file" do
    digits = read_all("../pi-500.txt")

    assert String.starts_with? digits, "3.1415" 

    first_few = digits |> String.slice 0..6
    assert first_few != "3.11111"
  end

  test "syntax comparison" do
    digits = read_all("../pi-500.txt")

    # compare these syntaxes ways
    first_few = digits |> String.slice 0..6
    assert first_few == "3.14159"

    first_few = digits |> String.slice(0..6)
    assert first_few == "3.14159"

    first_few = String.slice digits, 0..6
    assert first_few == "3.14159"

    first_few = String.slice(digits, 0..6)
    assert first_few == "3.14159"

  end

  test "punctuation strings" do
    assert (String.upcase ",") == (String.downcase ",")

    assert     is_punctuation "!"
    assert not is_punctuation "d"
  end

  def is_punctuation(sample) do
    (String.upcase sample) == (String.downcase sample)
  end

  def encodes_zero(sample) do
    (String.upcase sample) == (String.downcase sample) and sample != "."
  end

  test "encoding of zeroes" do
    assert (String.upcase ",") == (String.downcase ",")

    assert     encodes_zero "!"
    assert not encodes_zero "d"
    assert not encodes_zero "."
  end

end
