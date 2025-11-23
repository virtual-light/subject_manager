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

  @spec get!(Subject.id()) :: Subject.t()
  def get!(id), do: Repo.get!(Subject, id)

  @spec list_subjects(params()) :: [Subject.t()]
  def list_subjects(params) do
    from(s in Subject)
    |> apply_params(params)
    |> Repo.all()
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
end
