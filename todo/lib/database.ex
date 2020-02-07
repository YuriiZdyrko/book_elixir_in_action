defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"
  @num_workers 3

  def start_link(_) do
    workers =
      1..@num_workers
      |> Enum.map(fn i ->
        {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder)
        {i, pid}
      end)
      |> Enum.into(%{})

    GenServer.start_link(__MODULE__, workers, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def choose_worker(pool, key) do
    Map.fetch!(pool, :erlang.phash2(key, 3))
  end

  @impl GenServer
  def init(state) do
    File.mkdir_p!(@db_folder)
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    worker = choose_worker(state, key)

    Todo.DatabaseWorker.store(worker, key, data)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    worker = choose_worker(state, key)

    {:reply, Todo.DatabaseWorker.get(worker, key), state}
  end
end

defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(db_folder) do
    IO.puts("Starting Database worker")
    GenServer.start_link(__MODULE__, db_folder, [])
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  @impl GenServer
  def init(folder) do
    {:ok, folder}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    file_name(state, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(state, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end
