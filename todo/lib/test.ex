defmodule Todo.Test do
  @doc """
  Demonstrate that no dangling Server workers are left running when
  top-most Cache worker goes down.

  bobs_list process is removed and re-created.
  """
  def list_existing do
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

  def trigger_max_restart() do
    {:ok, _supervisor_pid} = Todo.System.start_link()

    for _ <- 1..4 do
      Process.exit(Process.whereis(Todo.Cache), :kill)
      Process.sleep(200)
    end
  end
end
