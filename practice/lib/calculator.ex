defmodule Calc do
  def run do
    pid = start()
    add(pid, 10)
    sub(pid, 4)
    value(pid)

    add(pid, 2)
    value(pid)
  end

  # Interface
  def start do
    spawn(&loop/0)
  end

  def add(calc_pid, val) do
    send(calc_pid, {:add, val})
  end

  def sub(calc_pid, val) do
    send(calc_pid, {:subtract, val})
  end

  def value(calc_pid) do
    send(calc_pid, {:value, self()})

    receive do
      {:value, value} ->
        IO.puts("value: #{to_string(value)}")
    end
  end

  # Implementation
  def loop(state \\ 0) do
    next_state =
      receive do
        {:add, value} ->
          IO.inspect("add #{to_string(value)}")
          loop(state + value)

        {:subtract, value} ->
          IO.inspect("sub #{to_string(value)}")
          loop(state - value)

        {:value, caller_pid} ->
          send(caller_pid, {:value, state})
          loop(state)
      end
  end
end
