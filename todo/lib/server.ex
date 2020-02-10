defmodule Todo.ServerAgent do
  @moduledoc """
  Agent implementation, no expiration handling
  """

  use Agent, restart: :temporary

  def start_link(name) do
    Agent.start_link(
      fn -> 
        IO.puts("Starting to-do server for #{name}")
        {name, Todo.Database.get(name) || Todo.List.new()}
      end,
      name: via_tuple(name)
    )
  end

  def add_entry(todo_server, new_entry) do
    Agent.cast(todo_server, fn {name, todo_list} -> 
      new_list = Todo.List.add_entry(todo_list, new_entry)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def entries(todo_server, date) do
    Agent.get(todo_server, fn {name, todo_list} -> 
      Todo.List.entries(todo_list, date)
    end)
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end


defmodule Todo.Server do
  @moduledoc """
  GenServer implementation, with expiration handling.
  If there's no call/cast for @expiry_timeout, :timeout info will fire
  """
  use GenServer, restart: :temporary

  @expiry_timeout :timer.seconds(10)

  def start_link(name) do
    GenServer.start_link(
      __MODULE__,
      name,
      name: via_tuple(name)
    )
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  @impl GenServer
  def init(name) do
    IO.puts("Starting to-do server for #{name}")
    {
      :ok, 
      {name, Todo.Database.get(name) || Todo.List.new()},
      @expiry_timeout  
    }
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}, @expiry_timeout}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list},
      @expiry_timeout
    }
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    IO.inspect("Server #{name} timed out. stopping...")
    {:stop, :normal, {name, todo_list}}
  end
end

