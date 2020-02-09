defmodule Todo.Test do
  @doc """
  Demonstrate that no dangling Server workers are left running when
  top-most Cache worker goes down.

  bobs_list process is removed and re-created.
  """
  def list_existing do
    cleanup()
    {:ok, _supervisor_pid} = Todo.System.start_link()

    bobs_list = Todo.Cache.server_process("bobs_list")

    Todo.Server.entries(bobs_list, ~D[2018-12-19])

    Todo.Server.entries(
      bobs_list,
      ~D[2018-12-19]
    )

    IO.inspect(:erlang.system_info(:process_count))

    Process.exit(Process.whereis(Todo.Cache), :kill)

    Process.sleep(1000)

    bobs_list = Todo.Cache.server_process("bobs_list")

    IO.inspect(:erlang.system_info(:process_count))
  end

  @doc """
  By default Supervisor has max_restart: 3, max_seconds: 5
  So in this case Todo.System goes down with Todo.Cache
  """
  def trigger_max_restart() do
    cleanup()
    {:ok, _supervisor_pid} = Todo.System.start_link()

    for _ <- 1..4 do
      Process.exit(Process.whereis(Todo.Cache), :kill)
      Process.sleep(200)
    end
  end

  @doc """
  Demonstrate :one_for_one supervisor strategy

  While Todo.Database and Todo.DatabaseWorkers are restarted,
  Todo.Servers are unaffected, and can handle :get requests
  """
  def error_effects_isolation() do
    cleanup()
    Todo.System.start_link()

    bobs_list = Todo.Cache.server_process("bobs_list")

    {pid, _} =
      Registry.lookup(
        Todo.ProcessRegistry,
        {Todo.DatabaseWorker, 1}
      )

    Process.exit(pid, :kill)

    Todo.Server.entries(
      bobs_list,
      ~D[2018-12-19]
    )
  end


  def server_supervision do
    cleanup()

    Todo.System.start_link()

    alices_list = Todo.Cache.server_process("Alice's list")
    bobs_list = Todo.Cache.server_process("Bob's list")
    bobs_list2 = Todo.Cache.server_process("Bob's list")

    bobs_list == bobs_list2

    IO.inspect("bobs list before kill #{inspect bobs_list}")
    IO.inspect("alices list before kill #{inspect alices_list}")

    Process.exit(bobs_list, :kill)

    bobs_list = Todo.Cache.server_process("Bob's list")
    alices_list = Todo.Cache.server_process("Alice's list")

    IO.inspect("bobs list after kill #{inspect bobs_list}")
    IO.inspect("alices list after kill #{inspect alices_list}")
  end

  def cleanup do
    pid = Process.whereis(Todo.System)
    if (pid != nil), do: Supervisor.stop(Todo.System, :cleanup)
    IO.inspect("cleanup:")
    IO.inspect(Process.whereis(Todo.ProcessRegistry))
  end
end
