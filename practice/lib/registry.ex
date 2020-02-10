defmodule MyRegistry do
  @moduledoc """
  Provides register/1 and whereis/1 methods
  if process fails, deregisters it.
  """
  use GenServer

  def test do
    __MODULE__.start_link(nil)

    {:ok, w1} =
      Agent.start(fn ->
        __MODULE__.register(:one)
        1
      end)

    {:ok, w2} =
      Agent.start(fn ->
        __MODULE__.register(:two)
        2
      end)

    {:ok, w3} =
      Agent.start(fn ->
        __MODULE__.register(:three)
        3
      end)

    {:ok, w4} =
      Agent.start(fn ->
        __MODULE__.register(:four)

        spawn_link(fn ->
          Process.sleep(2000)
          raise ":four error"
        end)

        3
      end)

    puts_inspect("self() pid", self())
    puts_inspect("MyRegistry pid", Process.whereis(__MODULE__))
    puts_inspect("MyRegistry state", __MODULE__.list())

    Process.exit(w1, :normal)
    Process.exit(w2, :nuked_from_the_orbit)
    Process.exit(w3, :kill)

    Process.sleep(1)

    puts_inspect("state", __MODULE__.list())

    nil
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register(name) do
    Process.link(Process.whereis(MyRegistry))
    GenServer.cast(MyRegistry, {:register, self(), name})
  end

  def whereis(name) do
    GenServer.call(__MODULE__, {:whereis, name})
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  # @impl GenServer
  def init(map) do
    Process.flag(:trap_exit, true)
    {:ok, map}
  end

  # @impl GenServer
  def handle_cast({:register, pid, name}, state) do
    {:noreply, Map.put(state, name, pid)}
  end

  # @impl GenServer
  def handle_call({:whereis, name}, _, state) do
    {:reply, state[name], state}
  end

  def handle_call(list, _, state) do
    {:reply, state, state}
  end

  # @impl GenServer
  def handle_info({:EXIT, pid, reason}, state) do
    new_state =
      state
      |> Enum.filter(fn {key, value} ->
        value != pid
      end)
      |> Enum.into(%{})

    puts_inspect(":EXIT reason", reason)
    puts_inspect(":EXIT new_state", new_state)

    {:noreply, new_state}
  end

  def handle_info(other, state) do
    puts_inspect("other", other)

    {:noreply, state}
  end

  def puts_inspect(p, i) do
    Process.sleep(100)
    IO.inspect("#{p} > #{inspect(i)}")
  end
end
