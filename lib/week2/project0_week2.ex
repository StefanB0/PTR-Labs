defmodule Project0_Week2 do
  @moduledoc """
  The Project0_Week2 module provides all the functions necessary for the first checkpoint of project 0 on PTR
  """

  def is_prime(x) when x < 2, do: false
  def is_prime(x), do: 2..x |> Enum.filter(fn a -> rem(x, a) == 0 end) |> length() == 1

  def cylinder_area({radius, height}),
    do: (2 * :math.pi() * radius * height + 2 * :math.pi() * radius * radius) |> Float.round(4)

  def reverse_list(list), do: reverse_list(list, [])
  def reverse_list([head | tail], new_list), do: reverse_list(tail, [head | new_list])
  def reverse_list([], new_list), do: new_list

  def unique_sum(list), do: Enum.uniq(list) |> Enum.sum()

  def extract_random_n(list, n), do: Enum.take_random(list, n)

  def first_fibonacci_elements(n) when n == 1 or n == 2, do: List.duplicate(1, n)
  def first_fibonacci_elements(n), do: first_fibonacci_elements(n, [1, 1])

  def first_fibonacci_elements(n, arr) when length(arr) < n,
    do: first_fibonacci_elements(n, arr ++ [List.last(arr) + Enum.at(arr, length(arr) - 2)])

  def first_fibonacci_elements(_n, arr), do: arr

  def translator(dictionary, sentence) do
    String.split(sentence)
    |> Enum.map(&if Map.has_key?(dictionary, &1), do: dictionary[&1], else: &1)
    |> Enum.join(" ")
  end

  @doc """
  ##Test

      iex>Project0_Week2.smallestNumber(3, 1, 0)
      103

      iex>Project0_Week2.smallestNumber(4, 4, 2)
      244

  """
  def smallestNumber(x, y, z) do
    [x, y, z]
    |> Enum.sort()
    |> case(
      do:
        (
          [0, 0, z] -> [z, 0, 0]
          [0, y, z] -> [y, 0, z]
          l -> l
        )
    )
    |> Enum.join()
    |> String.to_integer()
  end

  def rotateLeft(list, n), do: Enum.reduce(1..n, list, fn _x, l -> tl(l) ++ [hd(l)] end)

  def listRightAngleTriangles() do
    n = 20
    c = &:math.sqrt(&1 * &1 + &2 * &2)

    for i <- 1..n, j <- 1..n, c.(i, j) == floor(c.(i, j)) do
      [i, j, floor(c.(i, j))]
    end
    |> Enum.map(&Enum.sort/1)
    |> Enum.uniq()
  end

  def removeConsecutiveDuplicates(enumerable) do
    Enum.dedup(enumerable)
  end

  def lineWords(list) do
    lineset = [
      ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
      ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      ["z", "x", "c", "v", "b", "n", "m"]
    ]

    Enum.filter(list, fn word ->
      String.downcase(word)
      |> String.graphemes()
      |> then(fn ch_word ->
        Enum.any?(lineset, fn row ->
          Enum.all?(ch_word, &(&1 in row))
        end)
      end)
    end)
  end

  def encode(message, n) do
    add = fn
      {ch, n} when ch in ?a..?z -> rem(ch - ?a + n, 26) + ?a
      {ch, n} when ch in ?A..?Z -> rem(ch - ?A + n, 26) + ?A
      {ch, _n} -> ch
    end

    message |> to_charlist() |> Enum.map(&add.({&1, n})) |> to_string()
  end

  def decode(message, n) do
    sub = fn
      {ch, n} when ch in ?a..?z -> rem(ch - ?a + 26 - n, 26) + ?a
      {ch, n} when ch in ?A..?Z -> rem(ch - ?A + 26 - n, 26) + ?A
      {ch, _n} -> ch
    end

    message |> to_charlist() |> Enum.map(&sub.({&1, n})) |> to_string()
  end

  def letterCombinations(message) do
    dictionary = %{
      "2" => ["a", "b", "c"],
      "3" => ["d", "e", "f"],
      "4" => ["g", "h", "i"],
      "5" => ["j", "k", "l"],
      "6" => ["m", "n", "o"],
      "7" => ["p", "q", "r", "s"],
      "8" => ["t", "u", "v"],
      "9" => ["w", "x", "y", "z"]
    }

    expandLetter = fn
      {message, func} ->
        func.({tl(message), dictionary[hd(message)], func})

      {[], acc, _func} ->
        acc

      {message, acc, func} ->
        func.({
          tl(message),
          Enum.map(acc, fn word ->
            Enum.map(dictionary[hd(message)], fn letter -> word <> letter end)
          end)
          |> Enum.concat(),
          func
        })
    end

    expandLetter.({message |> String.graphemes(), expandLetter})
  end

  def groupAnagrams(list) do
    simplify = fn word -> String.graphemes(word) |> Enum.sort() |> Enum.join() end
    groups = list |> Enum.map(&simplify.(&1)) |> Enum.uniq() |> Map.new(&{&1, []})

    list
    |> Enum.reduce(groups, fn x, acc -> Map.put(acc, simplify.(x), acc[simplify.(x)] ++ [x]) end)
  end

  def toRoman(nr), do: toRoman(nr, "")

  @spec toRoman(integer(), String.t()) :: String.t()
  def toRoman(0, roman_nr), do: roman_nr

  def toRoman(nr, roman_nr) do
    case nr do
      nr when nr >= 1000 -> toRoman(nr - 1000, roman_nr <> "M")
      nr when nr >= 900 -> toRoman(nr - 900, roman_nr <> "CM")
      nr when nr >= 500 -> toRoman(nr - 500, roman_nr <> "D")
      nr when nr >= 400 -> toRoman(nr - 400, roman_nr <> "CD")
      nr when nr >= 100 -> toRoman(nr - 100, roman_nr <> "C")
      nr when nr >= 90 -> toRoman(nr - 90, roman_nr <> "XC")
      nr when nr >= 50 -> toRoman(nr - 50, roman_nr <> "L")
      nr when nr >= 40 -> toRoman(nr - 40, roman_nr <> "XL")
      nr when nr >= 10 -> toRoman(nr - 10, roman_nr <> "X")
      nr when nr == 9 -> toRoman(nr - 9, roman_nr <> "IX")
      nr when nr >= 5 -> toRoman(nr - 5, roman_nr <> "V")
      nr when nr == 4 -> toRoman(nr - 4, roman_nr <> "IV")
      nr when nr > 0 -> toRoman(nr - 1, roman_nr <> "I")
      _ -> :error
    end
  end

  def factorize(nr) do
    1..nr
    |> Enum.filter(&Project0_Week2.is_prime/1)
    |> Enum.filter(&(rem(nr, &1) == 0))
    |> factorize(nr, [])
  end

  def factorize([], _nr, factor_set), do: factor_set

  def factorize(prime_set, nr, factor_set) do
    if rem(nr, hd(prime_set)) == 0 do
      factorize(prime_set, div(nr, hd(prime_set)), factor_set ++ [hd(prime_set)])
    else
      factorize(tl(prime_set), nr, factor_set)
    end
  end

  def commonPrefix(list), do: commonPrefix(list, "")

  def commonPrefix(list, prefix) do
    newPrefix = list |> hd() |> String.split_at(String.length(prefix) + 1) |> elem(0)

    (Enum.filter(list, &String.starts_with?(&1, newPrefix)) |> length() == length(list))
    |> if(do: commonPrefix(list, newPrefix), else: prefix)
  end
end
