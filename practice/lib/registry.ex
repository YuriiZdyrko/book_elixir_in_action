defmodule MyRegistry do
    @moduledoc """
    Provides register/1 and whereis/1 methods
    if process fails, deregisters it.
    """
    use GenServer

    def test do
        __MODULE__.start_link(nil)

        {:ok, w1} = Agent.start_link(fn -> 
            1
         end)
        {:ok, w2} = Agent.start_link(fn -> 
            
            2
        end)
        {:ok, w3} = Agent.start_link(fn -> 
            
            3 
        end)

        Process.sleep(5000)

        MyRegistry.register(w1, :one)
        MyRegistry.register(w2, :two)
        MyRegistry.register(w3, :three)

        __MODULE__.whereis(:two) |> IO.inspect()
        Process.whereis(__MODULE__) |> IO.inspect()

        IO.inspect("exiting worker: ")
        IO.inspect(w2)

        count()
        sleep()

        
        Process.exit(w2, :not_normal)
        IO.puts("after exit")

        count()
        sleep()

        __MODULE__.whereis(:two) |> IO.inspect()

        IO.puts("registry:")
        Process.whereis(__MODULE__) |> IO.inspect()
    end
    
    def start_link(_) do
        GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def register(pid, name) do
        Process.link(Process.whereis(MyRegistry))
        GenServer.cast(__MODULE__, {:register, pid, name})
    end

    def whereis(name) do
        GenServer.call(__MODULE__, {:whereis, name})
    end

    # @impl GenServer
    def init(map) do
        IO.inspect("trapping exits")
        Process.flag(:trap_exit, true)
        {:ok, map}
    end

    # @impl GenServer
    def handle_cast({:register, pid, name}, state) do
        {:noreply, Map.put(state, name, pid)}
    end

    # @impl GenServer
    def handle_call({:whereis, name}, _, state) do
        {:reply, Map.fetch(state, name), state}
    end

    # @impl GenServer
    def handle_info({:EXIT, pid, reason}, state) do
        IO.puts(":EXIT handle_info")

        new_state = state
        |> Enum.filter(fn {key, value} -> 
            value != pid
        end)
        |> Enum.into(%{})

    
        IO.puts("new_state")
        count()
        sleep()

        Process.sleep(5000)
        # IO.inspect(new_state)

        {:noreply, new_state}
    end
    def handle_info(other, state) do
        IO.puts("other info")
        IO.inspect(other)

        {:noreply, state}
    end

    def count() do
        :erlang.system_info(:process_count)
        |> IO.inspect
    end

    def sleep() do
        Process.sleep(2000)
    end
end