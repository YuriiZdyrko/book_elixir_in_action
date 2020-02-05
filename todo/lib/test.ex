defmodule Todo.Test do
    def list_existing do
        {:ok, cache} = Todo.Cache.start()
        bobs_list = Todo.Cache.server_process("bobs_list")
        Todo.Server.entries(bobs_list, ~D[2018-12-19])

        Todo.Server.entries(
            bobs_list,
            ~D[2018-12-19]
        )
    end
end