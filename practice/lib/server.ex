defmodule Server do
  # Interface
  def start do
    spawn(&loop/0)
  end

  # Interface
  def run_async(server_pid, query) do
    # Possible to use here callers pid (self())
    send(server_pid, {:run_query, self(), query})
  end

  def get_result do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  # Implementation
  def loop() do
    receive do
      {:run_query, callers_pid, query} ->
        Process.sleep(1000)
        result = "Result #{query}"
        send(callers_pid, {:query_result, result})
    end

    loop()
  end
end

defmodule Client do
  def run do
    pool =
      1..100
      |> Enum.map(fn _ -> Server.start() end)

    ~w(a b c d e f g)
    |> Enum.map(fn char ->
      server_pid = Enum.at(pool, :rand.uniform(100) - 1)
      Server.run_async(server_pid, char)
    end)
    |> Enum.map(fn _ -> Server.get_result() end)
  end
end
