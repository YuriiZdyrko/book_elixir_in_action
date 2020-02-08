defmodule EchoServer do
    use GenServer

    def start_link(id) do
        GenServer.start_link(__MODULE__, id, name: via_tuple(id))
    end

    def init(id) do
        {:ok, id}
    end

    def via_tuple(id) do
        {:via, Registry, {:my_registry, {__MODULE__, id}}}
    end

    def handle_call(some_request, _, id) do
       {:reply, some_request, id} 
    end
end

defmodule EchoServerTest do
    alias EchoServer

    def test do
        Registry.start_link(name: :my_registry, keys: :unique)

        EchoServer.start_link("server one")
        EchoServer.start_link("server two")

        EchoServer.call("server one", :some_request)
    end
end