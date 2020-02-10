defmodule Tasks do
    def awaited do
        task = Task.async(fn -> 
            Process.sleep(2000)
            :success
        end)

        IO.inspect("See, parent isn't blocked by Task.async")

        result = Task.await(task) 

        IO.inspect("Task result: #{result}")
    end

    def non_awaited do
        task = Task.start_link(fn -> 
            Process.sleep(2000)
            IO.puts("inside a task")
        end)

        IO.inspect("See, parent isn't blocked by Task.async")
    end
end