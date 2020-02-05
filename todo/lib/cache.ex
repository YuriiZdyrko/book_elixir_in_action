defmodule Todo.Cache do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(todo_list_name) do
    GenServer.call(__MODULE__, {:get, todo_list_name})
  end

  def init(_) do
    # Ensure db is started
    Todo.Database.start()

    {:ok, %{}}
  end

  def handle_call({:get, todo_list_name}, _from, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end
