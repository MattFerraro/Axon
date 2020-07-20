defmodule AxonWeb.AxonLive do
  use AxonWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :brightness, 10)
    grbl_state = Axon.GrblConnection.view(:grbl)
    socket = assign(socket, :grbl_state, grbl_state)
    socket = assign(socket, :cmd, "$$")
    socket = assign(socket, :file_data, %{})
    socket = assign(socket, :token, Phoenix.Controller.get_csrf_token())
    Axon.GrblConnection.register(:grbl, self())

    file_state = Axon.FileHolder.get_state(:file_holder)
    socket = assign(socket, :file_state, file_state)
    Axon.FileHolder.register(:file_holder, self())
    {:ok, socket}
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

  def handle_event("xy-slew", source, socket) do
    IO.inspect source
    {:noreply, socket}
  end

  # def handle_event("phx-dropzone", ["generate-url", payload], socket) do
  #   IO.puts "GOT A PHX-DROPZONE GENERATE URL EVENT"
  #   IO.puts "payload:"
  #   IO.inspect payload
  #   retval = %{id: payload["id"], url: "/uploads/" <> payload["name"]}
  #   IO.puts "Using retval:"
  #   IO.inspect retval
  #   socket = assign(socket, :file_data, retval)
  #   {:noreply, socket}
  # end

  def handle_event("save", params, socket) do
    IO.inspect params
    path_upload = params["Elixir.AxonWeb.Endpoint"]["docfile"]
    IO.inspect path_upload
    File.cp(path_upload.path, Path.absname("uploads/#{path_upload.filename}"))
    {:noreply, socket}
  end

  # def handle_event("phx-dropzone", ["file-status", payload], socket) do
  #   IO.puts "Got a file status msg:"
  #   IO.inspect payload
  #   {:noreply, socket}
  # end

  def handle_info({:log_update, _msg}, socket) do
    {:noreply, socket |> assign(:grbl_state, Axon.GrblConnection.view(:grbl))}
  end

  def handle_info({:file_update, _msg}, socket) do
    {:noreply, socket |> assign(:grbl_state, Axon.FileHolder.get_state(:file_holder))}
  end
end
