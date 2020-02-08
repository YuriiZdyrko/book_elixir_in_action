defmodule Todo.Database do
  @db_folder "./persist"
  @num_workers 3

  def start_link() do
    File.mkdir_p!(@db_folder)
    children = Enum.map(1..@num_workers, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp worker_spec(worker_id) do
    default_worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}
    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  def choose_worker(key) do
    :erlang.phash2(key, @num_workers)
  end
end


defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link({db_folder, worker_id}) do
    IO.puts("Starting Database worker")

    name = Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})

    GenServer.start_link(__MODULE__, db_folder, [name: name])
  end

  def store(worker_id, key, data) do
    GenServer.cast(worker_id, {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(worker_id, {:get, key})
  end

  # @impl GenServer
  def init(folder) do
    {:ok, folder}
  end

  # @impl GenServer
  def handle_cast({:store, key, data}, state) do
    file_name(state, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  # @impl GenServer
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
