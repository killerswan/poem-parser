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
    ((String.upcase sample) == (String.downcase sample)) and not String.match?(sample, ~r/[0-9]/)
  end

  def encodes_zero(sample) do
    '''
    "Any punctuation mark other than a period represents a zero digit (a period stands fno digit)."
    ''' 
    is_punctuation(sample) and sample != "."
  end

  test "encoding of zeroes" do
    assert (String.upcase ",") == (String.downcase ",")

    assert     encodes_zero "!"
    assert not encodes_zero "d"
    assert not encodes_zero "."
  end

  def is_word_digit(sample) do
    '''
    "A digit written literally stands for the same digit in the expansion."
    '''
    String.match?(sample, ~r/^[0-9]$/)
  end

  test "a word can be a digit" do
    assert     is_word_digit "8"
    assert not is_word_digit "eight"
    assert not is_word_digit ""
    assert not is_word_digit "88"
  end

  def digits_from_simple_word(sample) do
    '''
    "merely count the number of letters in each word...to obtain the successive decimals to pi."
    "Words of longer than 9 letters represent two adjacent digits (for example, a twelve-letter word represents the two digits 1- 2)."
    '''

    is_digit = is_word_digit(sample)
    
    case sample do
      sample when is_digit -> sample
      sample               -> sample |> String.length |> Integer.to_string
    end
  end

  test "simple word translations" do
    assert "1"  == digits_from_simple_word "a"
    assert "10" == digits_from_simple_word "superfreak"
    assert "7"  == digits_from_simple_word "7"
  end

  def tokenize_words(content) do
    # split on non-zero punctuation
    content |> String.split [" ", "\n", "\r", "."], trim: true
  end

  test "tokenized words" do
    assert ["one", "two"] == tokenize_words "one two"
    assert ["one", "two"] == tokenize_words "one.two"
    assert ["one", "two"] == tokenize_words "one. \r\ntwo"
  end


  def insert_zeroes(word_or_words) do
    words = word_or_words |> String.split ~r/[^a-zA-Z]/

    # split into a list of words separated by zeroes
    List.foldr words, [], fn
      x,  []  -> [x]
      "", acc -> ["0"] ++ acc
      x,  acc -> [x, "0"] ++ acc
    end
  end

  test "tokens incl. zeroes" do
    assert ["one"] == insert_zeroes "one"
    assert ["one", "0", "two"] == insert_zeroes "one'two"
    assert ["one", "0", "0", "two"] == insert_zeroes "one'!two"

    tokens = tokenize_words "one-two.three"
    assert ["one-two", "three"] == tokens
    assert [["one", "0", "two"], ["three"]] == Enum.map tokens, fn(x) -> insert_zeroes(x) end
    assert ["one", "0", "two", "three"] == Enum.flat_map tokens, fn(x) -> insert_zeroes(x) end
  end
end







