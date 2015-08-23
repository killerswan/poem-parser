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

    assert String.starts_with? digits, "31415" 

    first_few = digits |> String.slice 0..5
    assert first_few != "311111"
  end

  test "syntax comparison" do
    digits = read_all("../pi-500.txt")

    # compare these syntaxes ways
    first_few = digits |> String.slice 0..5
    assert first_few == "314159"

    first_few = digits |> String.slice(0..5)
    assert first_few == "314159"

    first_few = String.slice digits, 0..5
    assert first_few == "314159"

    first_few = String.slice(digits, 0..5)
    assert first_few == "314159"

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


  def insert_zeroes(phrase) do
    '''
    split into a list of words separated by zeroes
    '''
    chars = String.graphemes phrase
    char_and_types = Enum.map chars, fn(char) -> {char, encodes_zero(char)} end

    {first_word, acc} = List.foldr char_and_types, {[], []}, fn
        {_, true},     {[], acc_words}        -> {[],                  ["0"] ++ acc_words}
        {_, true},     {next_word, acc_words} -> {[],                  ["0", Enum.join(next_word)] ++ acc_words}
        {char, false}, {next_word, acc_words} -> {[char] ++ next_word, acc_words}
      end

    case {first_word, acc} do
      {[], acc} -> acc
      {first_word, acc} -> [Enum.join(first_word)] ++ acc
    end
  end

  test "tokens incl. zeroes" do
    assert ["one"] == insert_zeroes "one"
    assert ["0", "one"] == insert_zeroes "%one"
    assert ["one", "0"] == insert_zeroes "one-"
    assert ["one", "0", "two"] == insert_zeroes "one'two"
    assert ["one", "0", "0", "two"] == insert_zeroes "one'!two"

    tokens = tokenize_words "one-two.three"
    assert ["one-two", "three"] == tokens
    assert [["one", "0", "two"], ["three"]] == Enum.map tokens, fn(x) -> insert_zeroes(x) end
    assert ["one", "0", "two", "three"] == Enum.flat_map tokens, fn(x) -> insert_zeroes(x) end
  end

  def parse_poem_as_digits(poem) do
    """
    poem
    |> fn(x) -> tokenize_words(x) end
    |> Enum.flat_map fn(x) -> insert_zeroes(x) end
    |> Enum.map fn(x) -> digits_from_simple_word(x) end
    |> Enum.join
    """
    words = tokenize_words poem
    words2 = Enum.flat_map words, fn(x) -> insert_zeroes(x) end
    digits = Enum.map words2, fn(x) -> digits_from_simple_word(x) end
    Enum.join digits
  end

  test "parsing poems" do
    assert "1234" == parse_poem_as_digits "I am the best"
    assert "01234" == parse_poem_as_digits "!I am the best"
    assert "12340" == parse_poem_as_digits "I am the best!"
  end
  
end







