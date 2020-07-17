defmodule AxonWeb.AxonLive do
  use AxonWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :brightness, 10)
    grbl_state = Axon.GrblConnection.view(:grbl)
    socket = assign(socket, :grbl_state, grbl_state)
    socket = assign(socket, :cmd, "$$")
    Axon.GrblConnection.register(:grbl, self())
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Serial Ports</h1>

    <%= @grbl_state.x %></br>
    <%= @grbl_state.y %></br>
    <%= @grbl_state.z %></br>

    <button phx-click="port-refresh">
    Refresh Ports
    </button></br>

    <%= for {key, _} <- @grbl_state.ports do %>
      </br>
      <%= if @grbl_state.connected == key do %>
      <button value="<%= key %>" phx-click="close">Close</button>
      <% else %>
        <%= if @grbl_state.connected == "" do %>
          <button value="<%= key %>" phx-click="connect">Connect</button>
        <% else %>
          <button disabled value="<%= key %>" phx-click="connect">Connect</button>
        <% end %>
      <% end %>
      <%= key %>
    <% end %>

    <div id="console-log" class="fake-console">
      <%= for logline <- Enum.reverse(@grbl_state.log) do %>
        <%= logline %> </br>
      <% end %>
    </div>

    <form phx-submit="send">
      <input type="text" name="q" value="<%= @cmd %>" placeholder="Grbl console" list="results" autocomplete="off"/>
      <button type="submit" phx-disable-with="Sending...">Send</button>
    </form>
    <button phx-click="clear">Clear</button>

    <script>
    function doStuff() {
      let grblConsole = document.getElementById("console-log");
      grblConsole.scrollTop = grblConsole.scrollHeight;
    }
    document.addEventListener('phx:update', doStuff);
    </script>

    """
  end

  def handle_event("port-refresh", _, socket) do
    Axon.GrblConnection.refresh_ports(:grbl)
    grbl_state = Axon.GrblConnection.view(:grbl)
    socket = assign(socket, :grbl_state, grbl_state)
    {:noreply, socket}
  end

  def handle_event("send", %{"q" => query}, socket) do
    Axon.GrblConnection.send_cmd(:grbl, query)
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end

  def handle_event("connect", %{"value" => uart}, socket) do
    Axon.GrblConnection.connect(:grbl, uart)
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end

  def handle_event("close", _, socket) do
    Axon.GrblConnection.close(:grbl)
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end

  def handle_event("clear", _, socket) do
    Axon.GrblConnection.clear_log(:grbl)
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end

  def handle_info({:log_update, _msg}, socket) do
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end
end
