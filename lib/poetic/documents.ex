defmodule Poetic.Documents do
  import Ecto.Query, warn: false

  alias Poetic.Repo
  alias Poetic.Documents.Upload

  def create_upload_from_plug_upload(%Plug.Upload{
        filename: filename,
        path: tmp_path,
        content_type: content_type
      }) do
    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()

    Repo.transaction(fn ->
      with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
           {:ok, upload} <-
             Upload.changeset(%Upload{}, %{
               filename: filename,
               content_type: content_type,
               hash: hash,
               size: size
             })
             |> Repo.insert(),
           :ok <- File.cp(tmp_path, Upload.local_path(upload.id, filename)) do
        upload
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def list_upload do
    Repo.all(Upload)
  end

  def get_upload!(id) do
    Upload
    |> Repo.get!(id)
  end
end
