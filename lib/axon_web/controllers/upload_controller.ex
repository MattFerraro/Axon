defmodule AxonWeb.UploadController do
  use AxonWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, inputs) do
    path_upload = inputs["post"]["image"]

    IO.inspect path_upload
    File.cp(path_upload.path, Path.absname("uploads/#{path_upload.filename}"))

    Axon.FileHolder.set_filename(:file_holder, path_upload.filename)

    json(conn, "Uploaded to a temporary directory")
  end

end
