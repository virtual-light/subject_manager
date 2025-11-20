defmodule SubjectManager.Subjects do
  alias SubjectManager.Subjects.Subject
  alias SubjectManager.Repo

  @type sort_by :: :name | :team | :position
  @type params :: %{
          q: String.t() | nil,
          sort_by: sort_by() | nil,
          position: Subject.position() | nil
        }

  @spec list_subjects(params()) :: [Subject.t()]
  def list_subjects(_params) do
    Repo.all(Subject)
  end
end
