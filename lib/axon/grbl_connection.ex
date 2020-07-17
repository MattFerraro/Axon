defmodule Axon.GrblConnection do
  use GenServer

  # client
  def start_link(_init_state) do
    init_state = %{
      ports: Circuits.UART.enumerate(),
      listeners: [], log: [], connected: "",
      uart_pid: -1, x: 0.0, y: 0.0, z: 0.0
    }
    GenServer.start_link(__MODULE__, init_state, name: :grbl)
  end

  def register(pid, listener_pid) do
    GenServer.call(pid, {:register, listener_pid})
  end

  def connect(pid, uart) do
    GenServer.call(pid, {:connect, uart})
    GenServer.call(pid, :start_dro)
  end

  def close(pid) do
    GenServer.call(pid, :close)
  end


  def send_cmd(pid, cmd) do
    GenServer.cast(pid, {:send_cmd, cmd})
  end

  def clear_log(pid) do
    GenServer.call(pid, :clear_log)
  end

  def refresh_ports(pid) do
    GenServer.call(pid, :refresh)
  end

  def view(pid) do
    GenServer.call(pid, :view)
  end


  # server
  def init(state) do
    {:ok, pid} = Circuits.UART.start_link
    {:ok, %{state | uart_pid: pid}}
  end

  def handle_cast({:send_cmd, cmd}, state) do
    IO.puts "start:" <> cmd <> ":end"
    Circuits.UART.write(state.uart_pid, cmd)
    {:noreply, state}
  end

  def handle_call(:close, _from, state) do
    IO.puts "Clossing uart connection"
    Circuits.UART.close(state.uart_pid)
    {:reply, :ok, %{state | connected: ""}}
  end

  def handle_call({:connect, uart}, _from, state) do
    # IO.puts "Connect to uart: " <> uart
    Circuits.UART.open(state.uart_pid, uart, speed: 115200, active: true, framing: {Circuits.UART.Framing.Line, separator: "\n"}, rx_framing_timeout: 500)
    {:reply, "success", %{state | connected: uart}}
  end

  def handle_call(:start_dro, _from, state) do
    IO.puts "STARTING DRO"
    Process.send_after(self(), :query_dro, 250)
    {:reply, :ok, state}
  end

  def handle_call(:view, _from, state) do
    {:reply, %{x: state.x, y: state.y, z: state.z, ports: state.ports, log: state.log, connected: state.connected, uart_pid: state.uart_pid}, state}
  end

  def handle_call({:register, listener_pid}, _from, state) do
    {:reply, :ok, %{state | listeners: [listener_pid | state.listeners]}}
  end

  def handle_call(:refresh, _from, state) do
    {:reply, :ok, %{state | ports: Circuits.UART.enumerate()}}
  end

  def handle_call(:clear_log, _from, state) do
    {:reply, :ok, %{state | log: []}}
  end

  def parse_dro(msg) do
    positions = msg |>
      String.split("|") |>
      Enum.find(fn(x) -> String.starts_with?(x, "MPos") end) |>
      String.replace("MPos:", "") |>
      String.split(",") |>
      Enum.map(&String.to_float/1)

    Enum.zip([:x, :y, :z], positions) |> Enum.into(%{})
  end

  def notify_listeners(state, msg) do
    live_listeners = Enum.filter(state.listeners, fn(x) -> Process.alive?(x) end)
    for listener <- live_listeners do
      send(listener, {:log_update, msg})
    end
    live_listeners
  end

  def handle_info({:circuits_uart, _source, msg}, state) do
    # If the message starts with a "<" char, don't update the log or anything
    # if the message is just "ok" then skip it entirely
    cond do
      String.starts_with?(msg, "ok") ->
        {:noreply, state}
      String.starts_with?(msg, "<") ->
        dro_state = parse_dro(msg)
        live_listeners = notify_listeners(state, "dro")
        {:noreply, Map.merge(%{state | listeners: live_listeners}, dro_state)}
      true ->
        live_listeners = notify_listeners(state, "log")
        {:noreply, %{state | listeners: live_listeners, log: [msg | state.log]}}
    end
  end

  def handle_info(:query_dro, state) do
    Circuits.UART.write(state.uart_pid, "?")
    Process.send_after(self(), :query_dro, 200)
    {:noreply, state}
  end
end
