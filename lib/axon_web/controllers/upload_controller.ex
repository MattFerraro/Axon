defmodule AxonWeb.UploadController do
  use AxonWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, inputs) do
    IO.puts "OKAY WE ARE IN BUSINESS!"
    IO.inspect inputs
    path_upload = inputs["post"]["image"]

    IO.inspect path_upload
    # IO.inspect path_upload.filename, label: "Photo upload information"
    File.cp(path_upload.path, Path.absname("uploads/#{path_upload.filename}"))

    Axon.FileHolder.set_filename(:file_holder, path_upload.filename)

    json(conn, "Uploaded to a temporary directory")
  end

  # def update(conn, inputs) do
  #   IO.puts "Whoa, update called!"
  #   IO.inspect conn
  #   IO.inspect inputs
  #   # path_upload = upload["docfile"]
  #   # IO.inspect path_upload
  #   # File.cp(path_upload.path, Path.absname("uploads/#{path_upload.filename}"))
  #   json(conn, "All done")
  # end

end
