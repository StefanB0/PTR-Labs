1..20
|> Enum.filter(fn x -> Project0_Week2.is_prime(x) end)
|> IO.inspect(label: "prime numbers between 1 and 20")

{4, 3} |> Project0_Week2.cylinder_area() |> IO.inspect(label: "cylinder area of {4, 3}")
[1, 2, 3] |> Project0_Week2.reverse_list() |> IO.inspect(label: "reverse list of [1, 2, 3]")

[1, 1, 1, 4, 2, 3]
|> Project0_Week2.unique_sum()
|> IO.inspect(label: "unique sum of [1, 1, 1, 4, 2, 3]")

Project0_Week2.first_fibonacci_elements(5) |> IO.inspect(label: "first 5 fibonaccy numbers")
Project0_Week2.smallestNumber(4, 1, 0) |> IO.inspect(label: "smallest number from 4, 1, 0")

Project0_Week2.rotateLeft([1, 2, 3, 4, 5], 22)
|> IO.inspect(label: "rotate left [1, 2, 3, 4, 5] 22 times")

Project0_Week2.listRightAngleTriangles()
|> IO.inspect(label: "list right angle triangles below 20")

Project0_Week2.removeConsecutiveDuplicates([1, 1, 1, 2, 2, 3, 2])
|> IO.inspect(label: " remove consecutive duplicates [1, 1, 1, 2, 2, 3, 2]")

Project0_Week2.lineWords(["Hello", "Alaska", "Dad", "Peace"])
|> IO.inspect(label: "line words function")

Project0_Week2.encode("et tu brutus", 17)
|> IO.inspect(label: "caesar cipher encode, et tu brutus")

Project0_Week2.decode("vk kl silklj", 17)
|> IO.inspect(label: "caesar cipher decode, vk kl silklj")

Project0_Week2.groupAnagrams(["eat", "tea", "tan", "ate", "nat", "bat"])
|> IO.inspect(label: "group anagrams:")

Project0_Week2.letterCombinations("22") |> IO.inspect(label: "letter combinations 22")
Project0_Week2.toRoman(7) |> IO.inspect(label: "translate to roman numbers (7)")
Project0_Week2.factorize(60) |> IO.inspect(label: "factorize a number 60")
