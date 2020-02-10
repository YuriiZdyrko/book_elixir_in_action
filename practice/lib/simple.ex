defmodule NaturalNums do
  def print(1), do: IO.puts(1)

  def print(n) do
    IO.puts(n)
    print(n - 1)
  end
end

defmodule InfiniteLoop do
  def loop() do
    IO.puts("lol")
    loop()
  end
end

defmodule Range do
  @moduledoc """
  Tail vs non-tail recurstion #1
  """

  def run do
    do_run(&non_tail/2)
    do_run(&tail/2)
  end

  defp do_run(func) do
    IO.inspect(func)
    IO.inspect(func.(1, 4))
  end

  def non_tail(n1, n2) when n1 == n2, do: []

  def non_tail(n1, n2) do
    [n1] ++ non_tail(n1 + 1, n2)
  end

  def tail(n1, n2, result \\ []) when n1 < n2 do
    tail(n1 + 1, n2, result ++ [n1])
  end

  def tail(n1, n2, result), do: result
end

defmodule Positive do
  @moduledoc """
  Tail vs non-tail recursion #2
  """

  def run do
    list = -10..10 |> Enum.to_list()
    do_run(&tail/1, list)
    do_run(&non_tail/1, list)
  end

  defp do_run(func, args) do
    IO.inspect(func.(args))
  end

  def tail([h | t], result \\ []) do
    if h > 0 do
      tail(t, result ++ [h])
    else
      tail(t, result)
    end
  end

  def tail([], result), do: result

  def non_tail([h | t] = list) do
    check(h) ++ non_tail(t)
  end

  def non_tail([]), do: []
  def check(n) when n > 0, do: [n]
  def check(n) when n <= 0, do: []
end
