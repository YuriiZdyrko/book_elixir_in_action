defmodule GServer do
    alias KeyValueStore

    def test do
        pid = KeyValueStore.start()
        KeyValueStore.put(pid, :some_key, :some_value)
        KeyValueStore.get(pid, :some_key)
    end

    def start(callback_module) do
        spawn(fn ->
                initial_state = callback_module.init()
                loop(callback_module, initial_state)
            end)
    end

    def call(server_pid, request) do
        send(server_pid, {:call, request, self()})

        receive do
            {:response, response} -> 
                response
        end
    end

    def cast(server_pid, request) do
        send(server_pid, {:cast, request})
    end

    defp loop(callback_module, current_state) do
        receive do
            {:call, request, caller} ->
                {response, new_state} =
                callback_module.handle_call(
                    request,
                    current_state
                )

                send(caller, {:response, new_state})
                loop(callback_module, new_state)
            
            {:cast, request} ->
                {response, new_state} =
                callback_module.handle_cast(
                    request,
                    current_state
                )

                loop(callback_module, new_state)
        end
    end
end

defmodule KeyValueStore do
    use GenServer

    def start do
        GenServer.start(KeyValueStore, nil)
    end

    def put(pid, key, value) do
        GenServer.cast(pid, {:put, key, value})
    end
    
    def get(pid, key) do
        GenServer.call(pid, {:get, key})
    end

    def init(_) do
        :timer.send_interval(5000, :cleanup)
        {:ok, %{}}
    end

    # @impl GenServer
    def handle_cast({:put, key, value}, state) do
        {:noreply, Map.put(state, key, value)}
    end

    # @impl GenServer
    def handle_call({:get, key}, _from, state) do
        {:reply, Map.get(state, key), state}
    end

    # @impl GenServer
    def handle_info(:cleanup, state) do
        {:noreply, state}
    end
end