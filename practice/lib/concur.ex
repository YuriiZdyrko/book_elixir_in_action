defmodule Concur do
  def demonstrate_sequential do
    long_query = fn v ->
      Process.sleep(2000)
      "Result #{to_string(v)}"
    end

    1..4
    |> Enum.map(&long_query.(&1))
  end

  def demonstrate_concurrent_with_tasks do
    # in order
    long_query = fn i ->
      Process.sleep(2000 + :rand.uniform(1000))
      IO.inspect(i)
    end

    1..4
    |> Enum.map(&Task.async(fn -> long_query.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  def demonstrate_concurrent do
    parent = self()

    long_query = fn v ->
      Process.sleep(2000 + :rand.uniform(1000))
      send(parent, {self(), "Result #{to_string(v)}"})
    end

    pids =
      1..4
      |> Enum.map(fn i ->
        spawn(fn -> long_query.(i) end)
      end)

    # in order
    pids
    |> Enum.map(fn pid ->
      IO.inspect("receiving")

      receive do
        {^pid, value} -> IO.inspect("Received #{to_string(value)}")
      end
    end)

    # no order
    # pids
    # |> Enum.map(fn pid -> 
    #     IO.inspect("receiving")
    #     receive do
    #         {_, value} -> IO.inspect("Received #{to_string value}")
    #         other -> IO.inspect other
    #     end
    # end)
  end
end
