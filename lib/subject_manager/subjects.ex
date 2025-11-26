defmodule SubjectManager.Subjects do
  alias SubjectManager.Subjects.Subject
  alias SubjectManager.Repo

  import Ecto.Query

  @type sort_by :: :name | :team | :position
  @type params :: %{
          q: String.t() | nil,
          sort_by: sort_by() | nil,
          position: Subject.position() | nil
        }

  @type upsert_params :: %{
          name: String.t(),
          team: String.t(),
          position: Subject.position(),
          bio: String.t() | nil,
          image_path: Path.t() | nil
        }

  @spec get!(Subject.id()) :: Subject.t()
  def get!(id), do: Repo.get!(Subject, id)

  @spec delete!(Subject.id()) :: :ok
  def delete!(id) do
    id
    |> get!()
    |> Repo.delete!()
    |> then(fn %{image_path: image_path} -> maybe_delete_image(image_path) end)

    :ok
  end

  @spec list_subjects() :: [Subject.t()]
  def list_subjects, do: Repo.all(Subject)

  @spec list_subjects(params()) :: [Subject.t()]
  def list_subjects(params) do
    from(s in Subject)
    |> apply_params(params)
    |> Repo.all()
  end

  @spec positions() :: %{required(Subject.position()) => String.t()}
  def positions, do: Ecto.Enum.mappings(Subject, :position)

  @spec create(upsert_params()) :: Subject.t()
  def create(params) do
    params =
      Map.update!(params, :image_path, fn path ->
        if is_nil(path), do: Subject.default_image_path(), else: path
      end)

    %Subject{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert!()
  end

  @spec update!(Subject.id(), upsert_params()) :: :ok
  def update!(id, params) do
    subject = get!(id)
    default_path = Subject.default_image_path()

    params =
      Map.update!(params, :image_path, fn path ->
        if is_nil(path), do: default_path, else: path
      end)

    changeset = Ecto.Changeset.change(subject, params)

    Repo.update!(changeset)

    old_image_path = subject.image_path

    if Ecto.Changeset.changed?(changeset, :image_path) and old_image_path != default_path do
      delete_image(old_image_path)
    end

    :ok
  end

  @spec images_path :: Path.t()
  def images_path do
    Path.join(
      static_dir(),
      Application.fetch_env!(:subject_manager, :images_dirname)
    )
  end

  defp apply_params(query, params) do
    query
    |> maybe_filter(params)
    |> maybe_order_by(params.sort_by)
  end

  defp maybe_filter(query, params) do
    where =
      true
      |> maybe_filter_by_position(params.position)
      |> maybe_filter_by_name(params.q)

    from query, where: ^where
  end

  defp maybe_filter_by_position(where, position) do
    if is_nil(position) do
      where
    else
      dynamic([s], s.position == ^position and ^where)
    end
  end

  defp maybe_filter_by_name(where, name) do
    if is_nil(name) do
      where
    else
      name = "%#{name}%"
      dynamic([s], like(s.name, ^name) and ^where)
    end
  end

  defp maybe_order_by(query, nil), do: query

  defp maybe_order_by(query, order_by) do
    from s in query, order_by: ^order_by
  end

  defp maybe_delete_image(image_path) do
    if not is_nil(image_path) and image_path != Subject.default_image_path() do
      delete_image(image_path)
    end
  end

  defp delete_image(image_path) do
    static_dir()
    |> Path.join(image_path)
    |> File.rm!()
  end

  defp static_dir do
    :subject_manager
    |> :code.priv_dir()
    |> Path.join("static")
  end
end
