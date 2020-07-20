defmodule Axon.FileHolder do
  use GenServer

  # client
  def start_link(_) do
    init_state = %{
      filename: "no file!",
      lines: [],
      listeners: []
    }
    GenServer.start_link(__MODULE__, init_state, name: :file_holder)
  end

  # Client
  def init(state) do
    {:ok, state}
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def set_filename(pid, filename) do
    GenServer.call(pid, {:set_filename, filename})
  end

  def register(pid, listener_pid) do
    GenServer.call(pid, {:register, listener_pid})
  end


  # Server
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:set_filename, filename}, _from, state) do
    lines =
      File.stream!("uploads/#{filename}")
        |> Stream.map(&String.trim/1)
        |> Stream.with_index
        |> Enum.to_list

    live_listeners = notify_listeners(state, "file_state")
    {:reply, :ok, %{state | filename: filename, lines: lines, listeners: live_listeners}}
  end

  def handle_call({:register, listener_pid}, _from, state) do
    {:reply, :ok, %{state | listeners: [listener_pid | state.listeners]}}
  end

  def notify_listeners(state, msg) do
    live_listeners = Enum.filter(state.listeners, fn(x) -> Process.alive?(x) end)
    for listener <- live_listeners do
      send(listener, {:file_update, msg})
    end
    live_listeners
  end

end
